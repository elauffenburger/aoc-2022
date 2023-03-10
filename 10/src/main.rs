extern crate libc;

use std::{
    collections::VecDeque,
    fmt::{Debug, Display},
    io::{self, BufRead},
    vec,
};

fn main() {
    if let Err(err) = emain() {
        println!("error: {err}");
    }
}

fn emain() -> Result<(), String> {
    let mut debug = false;

    let mut args: VecDeque<String> = std::env::args().skip(1).collect();
    while !args.is_empty() {
        let arg = args.pop_front().unwrap();

        match arg.as_str() {
            "-d" => {
                debug = true;

                match args.pop_front() {
                    None => {}
                    Some(arg) => match arg.as_str() {
                        "attach" => {
                            println!("waiting for debugger...");

                            unsafe {
                                let set: libc::sigset_t =
                                    (libc::SIGTRAP | libc::SIGINT).try_into().unwrap();

                                let mut sig: libc::c_int = 0;
                                if libc::sigwait(&set, &mut sig) != 0 {
                                    return Err("sigwait failed".into());
                                }

                                match sig {
                                    libc::SIGINT => return Err("caught SIGINT".into()),
                                    _ => {}
                                }
                            };
                        }
                        _ => return Err(format!("unknown debug option '{arg}'")),
                    },
                }
            }
            _ => return Err(format!("unexpected arg '{arg}'")),
        }
    }

    let mut cpu = Cpu::new(debug);

    let ops = parse_ops()?;
    cpu.run_all(ops.into())?;

    Ok(())
}

fn parse_ops() -> Result<Vec<Op>, String> {
    let stdin = io::BufReader::new(io::stdin());

    let mut ops = vec![];
    for maybe_line in stdin.lines() {
        let line = maybe_line.map_err(|err| format!("{err}"))?;

        ops.push(Op::try_from(line.as_str())?);
    }

    Ok(ops)
}

struct PendingOp {
    op: Op,
    cycles_left: u8,
}

struct Crt {
    cycle: u32,
    display: [bool; Crt::WIDTH * Crt::HEIGHT],
}

impl Crt {
    const WIDTH: usize = 40;
    const HEIGHT: usize = 6;

    pub fn new() -> Self {
        Self {
            cycle: 0,
            display: [false; Self::WIDTH * Self::HEIGHT],
        }
    }

    pub fn clock_high(self: &mut Self) {
        self.cycle += 1;
    }

    pub fn clock_low(self: &mut Self, sprite_x: i32) {
        self.display[self.cycle as usize - 1] = self.visible(sprite_x);

        println!("crt cycle: {}", self.cycle);
        println!("{}", self.draw());
    }

    pub fn draw(self: &mut Self) -> String {
        let mut out = String::new();
        for (i, val) in self.display.iter().enumerate() {
            if i >= self.cycle as usize {
                break;
            }

            if i > 0 && i % Self::WIDTH == 0 {
                out.push('\n');
            }

            out.push(if *val { '#' } else { '.' });
        }

        out
    }

    // pos is the 1-indexed position of the pixel being drawn this cycle.
    fn pos(self: &Self) -> usize {
        (self.cycle as usize - 1) % Self::WIDTH
    }

    fn visible(self: &Self, sprite_x: i32) -> bool {
        let pos = self.pos() as i32;
        let dist = sprite_x - pos;

        dist >= -1 && dist <= 1
    }
}

struct Cpu {
    cycle: u32,
    op: Option<PendingOp>,

    registers: Registers,
    crt: Crt,

    debug: bool,
}

impl Debug for Cpu {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.write_fmt(format_args!(
            "Cpu {{ cycle: {}, registers: Registers {{ x: {} }} }}",
            self.cycle, self.registers.x
        ))
    }
}

impl Cpu {
    pub fn new(debug: bool) -> Self {
        Self {
            cycle: 0,
            op: None,
            registers: Registers::default(),
            crt: Crt::new(),
            debug,
        }
    }

    pub fn run_all(self: &mut Self, mut ops: VecDeque<Op>) -> Result<(), String> {
        while !ops.is_empty() || self.is_working() {
            self.clock_high();

            if !self.is_working() {
                let op = ops.pop_front().unwrap();
                self.queue_op(op);
            }

            self.clock_low()?;
        }

        Ok(())
    }

    fn is_working(self: &Self) -> bool {
        self.op.is_some()
    }

    fn clock_high(self: &mut Self) {
        self.cycle += 1;
        self.crt.clock_high();

        if self.debug {
            println!("\nbefore: {self:#?}");
        }
    }

    fn clock_low(self: &mut Self) -> Result<(), String> {
        self.crt.clock_low(self.registers.x);

        self.do_work()?;

        if self.debug {
            println!("after: {self:#?}");
        }

        Ok(())
    }

    fn queue_op(self: &mut Self, op: Op) {
        self.op = Some(PendingOp {
            cycles_left: op.cycles(),
            op,
        });
    }

    fn do_work(self: &mut Self) -> Result<(), String> {
        Ok(match self.op {
            None => {}
            Some(ref mut op) => {
                op.cycles_left -= 1;

                // If we're done working on the op, mark it as no longer pending and run it.
                if op.cycles_left == 0 {
                    let op = self.op.take().unwrap();
                    op.op.run(self)?;
                }
            }
        })
    }
}

#[derive(Debug)]
struct Registers {
    x: i32,
}

impl Default for Registers {
    fn default() -> Self {
        Self { x: 1 }
    }
}

enum Op {
    AddX(i32),
    Noop,
}

impl<'a> TryFrom<&'a str> for Op {
    type Error = String;

    fn try_from(value: &'a str) -> Result<Self, Self::Error> {
        let parts: Vec<&str> = value.split(" ").collect();

        Ok(match parts.as_slice() {
            ["noop"] => Op::Noop,
            ["addx", val @ _] => Op::AddX(val.parse().map_err(|err| format!("{err}"))?),
            _ => todo!(),
        })
    }
}

impl Op {
    pub fn cycles(self: &Self) -> u8 {
        match self {
            Op::AddX(_) => 2,
            Op::Noop => 1,
        }
    }

    pub fn run(self: &Self, cpu: &mut Cpu) -> Result<(), String> {
        Ok(match self {
            Op::AddX(val) => cpu.registers.x += val,
            Op::Noop => {}
        })
    }
}
