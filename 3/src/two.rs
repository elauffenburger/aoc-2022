use std::collections::HashSet;

use crate::get_priority;

pub fn two() -> Result<u32, String> {
    let stdin = std::io::stdin();

    let mut result = 0;
    let mut lines_buf: Vec<HashSet<char>> = vec![];
    loop {
        let mut line = String::new();
        match stdin.read_line(&mut line) {
            Ok(n) => {
                if n == 0 {
                    break;
                }

                lines_buf.push(HashSet::from_iter(line.chars().filter(|ch| *ch != '\n')));
                if lines_buf.len() < 3 {
                    continue;
                }

                let common: HashSet<char> = HashSet::from_iter(
                    HashSet::from_iter(lines_buf[0].intersection(&lines_buf[1]).map(|ch| *ch))
                        .intersection(&lines_buf[2])
                        .map(|ch| *ch),
                );
                dbg!(common.clone());
                debug_assert!(common.iter().len() == 1);
                let priority = get_priority(*common.iter().next().ok_or("expected one dup")?)?;
                result += priority;

                lines_buf.clear();
            }
            Err(_) => {
                break;
            }
        }
    }

    Ok(result)
}
