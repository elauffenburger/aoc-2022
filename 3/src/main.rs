use std::{collections::HashSet, error::Error, io::Write};

mod one;
mod two;

fn main() -> Result<(), Box<dyn Error>> {
    let result = two::two()?;

    std::io::stdout().write_all(format!("{}\n", result).as_bytes())?;

    Ok(())
}

pub fn get_priority(ch: char) -> Result<u32, String> {
    match ch {
        'a'..='z' => Ok(ch as u32 - 'a' as u32 + 1),
        'A'..='Z' => Ok(ch as u32 - 'A' as u32 + 27),
        c => Err(format!("unexpected char: {}", c)),
    }
}
