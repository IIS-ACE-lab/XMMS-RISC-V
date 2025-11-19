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

// Define a Ram as a BlackBox
class BlockRam(wordWidth: Int, wordCount: BigInt) extends BlackBox {

  // SpinalHDL will look at Generic classes to get attributes which
  // should be used ad VHDL gererics / Verilog parameter
  // You can use String Int Double Boolean and all SpinalHDL base types
  // as generic value
  val generic = new Generic {
    val ADDR_WIDTH = log2Up(BlockRam.this.wordCount)
    val DATA_WIDTH = BlockRam.this.wordWidth
  }

  // Define io of the VHDL entiry / Verilog module
  val io = new Bundle {
    val clk     = in Bool
    val we      = in Bool
    val addr    = in UInt (log2Up(wordCount) bit)
    val din     = in Bits (wordWidth bit)
    val dout    = out Bits (wordWidth bit)
  }

  noIoPrefix()

  //Map the current clock domain to the io.clk pin
  mapClockDomain(clock=io.clk)
}

class MuraxBusBlockRam(onChipRamSize : BigInt, onChipRamHexFile : String, simpleBusConfig : SimpleBusConfig) extends Component{
  val io = new Bundle{
    val bus = slave(SimpleBus(simpleBusConfig))
  }

  val ram0 = new BlockRam(8, (onChipRamSize / 4).toInt)
  val ram1 = new BlockRam(8, (onChipRamSize / 4).toInt)
  val ram2 = new BlockRam(8, (onChipRamSize / 4).toInt)
  val ram3 = new BlockRam(8, (onChipRamSize / 4).toInt)

  val addr = (io.bus.cmd.address >> 2).resized

  val we0 = io.bus.cmd.payload.mask(0) && io.bus.cmd.valid && io.bus.cmd.payload.wr
  val we1 = io.bus.cmd.payload.mask(1) && io.bus.cmd.valid && io.bus.cmd.payload.wr
  val we2 = io.bus.cmd.payload.mask(2) && io.bus.cmd.valid && io.bus.cmd.payload.wr
  val we3 = io.bus.cmd.payload.mask(3) && io.bus.cmd.valid && io.bus.cmd.payload.wr

  val ram_out0 = Bits(8 bits)
  val ram_out1 = Bits(8 bits)
  val ram_out2 = Bits(8 bits)
  val ram_out3 = Bits(8 bits)

  ram0.io.dout <> ram_out0
  ram0.io.din  <> io.bus.cmd.payload.data(7 downto 0)
  ram0.io.addr <> addr
  ram0.io.we   <> we0

  ram1.io.dout <> ram_out1
  ram1.io.din  <> io.bus.cmd.payload.data(15 downto 8)
  ram1.io.addr <> addr
  ram1.io.we   <> we1

  ram2.io.dout <> ram_out2
  ram2.io.din  <> io.bus.cmd.payload.data(23 downto 16)
  ram2.io.addr <> addr
  ram2.io.we   <> we2

  ram3.io.dout <> ram_out3
  ram3.io.din  <> io.bus.cmd.payload.data(31 downto 24)
  ram3.io.addr <> addr
  ram3.io.we   <> we3

  io.bus.rsp.payload.data <> (ram_out3 ## ram_out2 ## ram_out1 ## ram_out0)

  io.bus.rsp.valid := RegNext(io.bus.cmd.fire && !io.bus.cmd.wr) init(False)
  io.bus.cmd.ready := True

  if(onChipRamHexFile != null){
  }
}


