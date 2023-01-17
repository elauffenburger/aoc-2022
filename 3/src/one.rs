use crate::get_priority;

pub fn one() -> Result<u32, String> {
    let stdin = std::io::stdin();

    let mut result = 0;
    loop {
        let mut line = String::new();
        match stdin.read_line(&mut line) {
            Ok(n) => {
                if n == 0 {
                    break;
                }

                // Split the line into two compartments.
                let line_len = line.len();
                let (compartment_one, compartment_two) =
                    (&line[0..line_len / 2], &line[line_len / 2..]);

                // Find the duplicate.
                'outer: for l in compartment_one.chars() {
                    for r in compartment_two.chars() {
                        if l == r {
                            let priority = get_priority(l)?;
                            result += priority;
                            break 'outer;
                        }
                    }
                }
            }
            Err(_) => {
                break;
            }
        }
    }

    Ok(result)
}
