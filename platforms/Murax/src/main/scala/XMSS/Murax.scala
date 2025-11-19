package XMSS

import spinal.core._
import spinal.lib._
import spinal.lib.bus.amba3.apb._
import spinal.lib.bus.misc.SizeMapping
import spinal.lib.com.jtag.Jtag
import spinal.lib.com.uart._
import spinal.lib.io.TriStateArray
import spinal.lib.misc.{InterruptCtrl, Prescaler, Timer}
import spinal.lib.soc.pinsec.{PinsecTimerCtrl, PinsecTimerCtrlExternal}
import vexriscv.demo._
import vexriscv.plugin._
import vexriscv.{VexRiscv, VexRiscvConfig, plugin}

import scala.collection.mutable.ArrayBuffer


case class MuraxConfig(coreFrequency : HertzNumber,
                       onChipRamSize      : BigInt,
                       onChipRamHexFile   : String,
                       Apb3HW             : Boolean, 
                       pipelineDBus       : Boolean,
                       pipelineMainBus    : Boolean,
                       pipelineApbBridge  : Boolean,
                       gpioWidth          : Int,
                       uartCtrlConfig     : UartCtrlMemoryMappedConfig,
                       cpuPlugins         : ArrayBuffer[Plugin[VexRiscv]]){
  require(pipelineApbBridge || pipelineMainBus, "At least pipelineMainBus or pipelineApbBridge should be enable to avoid wipe transactions")
}

object MuraxConfig{
  def default =  MuraxConfig(
    coreFrequency         = 50 MHz,  //12 MHz,
    onChipRamSize         = 128 kB, //200 kB,
    Apb3HW                = false, 
    onChipRamHexFile      = null,
    pipelineDBus          = true,
    pipelineMainBus       = false,
    pipelineApbBridge     = true,
    gpioWidth = 32,
    cpuPlugins = ArrayBuffer( //DebugPlugin added by the toplevel
      new PcManagerSimplePlugin(
        resetVector = 0x80000000l,
        relaxedPcCalculation = true
      ),
      new IBusSimplePlugin(
        interfaceKeepData = false,
        catchAccessFault = false
      ),
      new DBusSimplePlugin(
        catchAddressMisaligned = false,
        catchAccessFault = false,
        earlyInjection = false
      ),
      new CsrPlugin(
         config = CsrPluginConfig(
           catchIllegalAccess = false,
           mvendorid      = null,
           marchid        = null,
           mimpid         = null,
           mhartid        = null,
           misaExtensionsInit = 66,
           misaAccess     = CsrAccess.NONE,
           mtvecAccess    = CsrAccess.NONE,
           mtvecInit      = 0x80000020l,
           mepcAccess     = CsrAccess.READ_WRITE,
           mscratchGen    = false,
           mcauseAccess   = CsrAccess.READ_ONLY,
           mbadaddrAccess = CsrAccess.READ_ONLY,
           mcycleAccess   = CsrAccess.READ_ONLY,
           minstretAccess = CsrAccess.READ_ONLY,
           ecallGen       = false,
           wfiGen         = false,
           ucycleAccess   = CsrAccess.NONE
         )
     ),
      new DecoderSimplePlugin(
        catchIllegalInstruction = false
      ),
      new RegFilePlugin(
        regFileReadyKind = plugin.SYNC,
        zeroBoot = false
      ),
      new IntAluPlugin,
      new SrcPlugin(
        separatedAddSub = false,
        executeInsertion = false
      ),
      // new MulPlugin,
      // new DivPlugin,
      new FullBarrelShifterPlugin,
      new HazardSimplePlugin(
        bypassExecute = true,
        bypassMemory = true,
        bypassWriteBack = true,
        bypassWriteBackBuffer = true,
        pessimisticUseSrc = false,
        pessimisticWriteRegFile = false,
        pessimisticAddressMatch = false
      ),
      new BranchPlugin(
        earlyBranch = false,
        catchAddressMisaligned = false,
        prediction = NONE
      ),
      new YamlPlugin("cpu0.yaml")
    ),
    uartCtrlConfig = UartCtrlMemoryMappedConfig(
      uartCtrlConfig = UartCtrlGenerics(
        dataWidthMax      = 8,
        clockDividerWidth = 20,
        preSamplingSize   = 1,
        samplingSize      = 3,
        postSamplingSize  = 1
      ),
      initConfig = UartCtrlInitConfig(
        baudrate = 9600, //115200,
        dataLength = 7,  //7 => 8 bits
        parity = UartParityType.NONE,
        stop = UartStopType.ONE
      ),
      busCanWriteClockDividerConfig = true,
      busCanWriteFrameConfig = false,
      txFifoDepth = 16,
      rxFifoDepth = 16
    )
  )
}



case class Murax(config : MuraxConfig) extends Component{
  import config._

  val io = new Bundle {
    //Clocks / reset
    val asyncReset = in Bool
    val mainClk = in Bool

    //Main components IO
    val jtag = slave(Jtag())

    //Peripherals IO
    val gpioA = master(TriStateArray(gpioWidth bits))
    val uart = master(Uart())
  }

  val resetCtrlClockDomain = ClockDomain(
    clock = io.mainClk,
    config = ClockDomainConfig(
      //resetKind = spinal.core.ASYNC
      resetKind = BOOT
    )
  )

  val resetCtrl = new ClockingArea(resetCtrlClockDomain) {
    val mainClkResetUnbuffered  = False

    //Implement an counter to keep the reset axiResetOrder high 64 cycles
    // Also this counter will automatically do a reset when the system boot.
    val systemClkResetCounter = Reg(UInt(6 bits)) init(0)
    when(systemClkResetCounter =/= U(systemClkResetCounter.range -> true)){
      systemClkResetCounter := systemClkResetCounter + 1
      mainClkResetUnbuffered := True
    }
    when(BufferCC(io.asyncReset)){
      systemClkResetCounter := 0
    }

    //Create all reset used later in the design
    val mainClkReset = RegNext(mainClkResetUnbuffered)
    val systemReset  = RegNext(mainClkResetUnbuffered)
  }


  val systemClockDomain = ClockDomain(
    clock = io.mainClk,
    reset = resetCtrl.systemReset,
    frequency = FixedFrequency(coreFrequency)
  )

  val debugClockDomain = ClockDomain(
    clock = io.mainClk,
    reset = resetCtrl.mainClkReset,
    frequency = FixedFrequency(coreFrequency)
  )

  val system = new ClockingArea(systemClockDomain) {
    val simpleBusConfig = SimpleBusConfig(
      addressWidth = 32,
      dataWidth = 32
    )

    //Arbiter of the cpu dBus/iBus to drive the mainBus
    //Priority to dBus, !! cmd transactions can change on the fly !!
    val mainBusArbiter = new MuraxMasterArbiter(simpleBusConfig)

    //Instanciate the CPU
    val cpu = new VexRiscv(
      config = VexRiscvConfig(
        plugins = cpuPlugins += new DebugPlugin(debugClockDomain)
      )
    )

    //Checkout plugins used to instanciate the CPU to connect them to the SoC
    val timerInterrupt = False
    val externalInterrupt = False
    for(plugin <- cpu.plugins) plugin match{
      case plugin : IBusSimplePlugin => mainBusArbiter.io.iBus <> plugin.iBus
      case plugin : DBusSimplePlugin => {
        if(!pipelineDBus)
          mainBusArbiter.io.dBus <> plugin.dBus
        else {
          mainBusArbiter.io.dBus.cmd << plugin.dBus.cmd.halfPipe()
          mainBusArbiter.io.dBus.rsp <> plugin.dBus.rsp
        }
      }
      case plugin : CsrPlugin        => {
        plugin.externalInterrupt := externalInterrupt
        plugin.timerInterrupt := timerInterrupt
      }
      case plugin : DebugPlugin         => plugin.debugClockDomain{
        resetCtrl.systemReset setWhen(RegNext(plugin.io.resetOut))
        io.jtag <> plugin.io.bus.fromJtag()
      }
      case _ =>
    }



    //****** MainBus slaves ********
    //val ram = new MuraxSimpleBusRam(
    val ram = new MuraxBusBlockRam(
      onChipRamSize = onChipRamSize,
      onChipRamHexFile = onChipRamHexFile,
      simpleBusConfig = simpleBusConfig
    )

    val apbBridge = new MuraxSimpleBusToApbBridge(
      apb3Config = Apb3Config(
        addressWidth = 20,
        dataWidth = 32
      ),
      pipelineBridge = pipelineApbBridge,
      simpleBusConfig = simpleBusConfig
    )



    //******** APB peripherals *********
    val gpioACtrl = Apb3Gpio(gpioWidth = gpioWidth)
    io.gpioA <> gpioACtrl.io.gpio

    val uartCtrl = Apb3UartCtrl(uartCtrlConfig)
    uartCtrl.io.uart <> io.uart
    externalInterrupt setWhen(uartCtrl.io.interrupt)

    val timer = new MuraxApb3Timer()
    timerInterrupt setWhen(timer.io.interrupt)


    //******** Memory mappings *********
    val apbSlaves = ArrayBuffer[(Apb3, SizeMapping)](
                      gpioACtrl.io.apb    -> (0x00000, 4 kB),
                      uartCtrl.io.apb     -> (0x10000, 4 kB),
                      timer.io.apb        -> (0x20000, 4 kB)
                    )
    
    if (config.Apb3HW) {
       val hw_accelerator = new Apb3HW()
       apbSlaves += hw_accelerator.io.apb -> (0x30000, 4 kB)
    }
 
    val apbDecoder = Apb3Decoder(
      master = apbBridge.io.apb,
      slaves = apbSlaves
    )

    val mainBusDecoder = new Area {
      val logic = new MuraxSimpleBusDecoder(
        master = mainBusArbiter.io.masterBus,
        specification = List[(SimpleBus,SizeMapping)](
          ram.io.bus             -> (0x80000000l, 1000 kB), //onChipRamSize kB),
          apbBridge.io.simpleBus -> (0xF0000000l, 1 MB)
        ),
        pipelineMaster = pipelineMainBus
      )
    }
  }
}


object Murax{
  def main(args: Array[String]) {
    SpinalConfig.shell(args).copy(netlistFileName = "Murax.v").generate(
          Murax(MuraxConfig.default)
    )
  }
}

object MuraxHW{
  def main(args: Array[String]) {
    SpinalConfig.shell(args).copy(netlistFileName = "MuraxHW.v").generate(
          Murax(MuraxConfig.default.copy(Apb3HW=true))
               .setDefinitionName("MuraxHW")
    )
  }
}
 