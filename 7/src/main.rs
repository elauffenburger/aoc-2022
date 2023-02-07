use std::cell::RefCell;
use std::collections::HashMap;
use std::io::{self, Read};
use std::rc::Rc;

fn main() {
    emain().unwrap()
}

fn emain() -> Result<(), String> {
    let stdin = io::stdin();
    let input = {
        let mut input = String::new();

        loop {
            let mut buf = String::new();
            let n = stdin
                .read_line(&mut buf)
                .map_err(|_| String::from("io err"))?;
            if n == 0 {
                break;
            }

            input.push_str(&buf);
        }

        input
    };

    let root = read_dirs(&input)?;
    let dir_sizes = get_dir_sizes(root);

    two(dir_sizes);

    Ok(())
}

fn one(dir_sizes: HashMap<String, u32>) {
    let sum_of_matching_sizes: u32 = dir_sizes
        .iter()
        .filter(|(_, size)| **size < 100000)
        .map(|(name, size)| {
            println!("{name} {size}");

            size
        })
        .sum();

    println!("{sum_of_matching_sizes}");
}

fn two(dir_sizes: HashMap<String, u32>) {
    const MAX_FREE_SPACE: u32 = 70000000;
    const REQUIRED_SPACE: u32 = 30000000;

    let used_space = MAX_FREE_SPACE - dir_sizes.get("/").unwrap();

    let best_fit: u32 = {
        let mut candidates: Vec<u32> = dir_sizes
            .iter()
            .filter(|(_, size)| used_space + **size >= REQUIRED_SPACE)
            .map(|(name, size)| {
                println!("{name} {size}");

                *size
            })
            .collect();

        candidates.sort();
        *candidates.get(0).unwrap()
    };

    println!("{best_fit}");
}

fn get_dir_sizes(root: Rc<RefCell<DirEntry>>) -> HashMap<String, u32> {
    let mut sizes = HashMap::new();
    get_dir_sizes_rec(root, &mut sizes, None, 0);

    sizes
}

fn get_dir_sizes_rec(
    dir: Rc<RefCell<DirEntry>>,
    sizes: &mut HashMap<String, u32>,
    parent_path: Option<&str>,
    depth: usize,
) -> u32 {
    let dir_path = match parent_path {
        Some(parent_path) => match parent_path {
            "/" => format!("/{}", dir.borrow().name.clone()),
            _ => format!("{}/{}", parent_path, dir.borrow().name),
        },
        None => dir.borrow().name.clone(),
    };

    println!("{}- {} (dir)", " ".repeat(depth), dir.borrow().name);

    let size: u32 = dir
        .borrow()
        .files
        .iter()
        .map(|file| {
            let size = file.size;
            println!(
                "{}- {} (file, size={size})",
                " ".repeat(depth + 1),
                file.name
            );

            size
        })
        .sum();

    let child_dirs_size: u32 = dir
        .borrow()
        .dirs
        .iter()
        .map(|dir| get_dir_sizes_rec(dir.clone(), sizes, Some(&dir_path), depth + 1))
        .sum();

    let total_size = size + child_dirs_size;
    sizes.insert(dir_path, total_size);

    total_size
}

fn read_dirs(input: &str) -> Result<Rc<RefCell<DirEntry>>, String> {
    let root = Rc::new(RefCell::new(DirEntry::new(None, "/")));

    let mut curr_dir = root.clone();
    let mut in_ls = false;
    for line in input.split("\n") {
        let line = parse_line(line)?;
        match line {
            ParsedLine::Command(cmd) => {
                // Mark that we're no longer in an ls.
                in_ls = false;

                match cmd {
                    Command::Ls => {
                        // Mark that we're in an ls.
                        in_ls = true;
                    }
                    Command::Cd(cd) => match cd {
                        CdDir::Up => {
                            // Go up a dir.
                            let parent = curr_dir.borrow().parent.clone().unwrap();
                            curr_dir = parent;
                        }
                        CdDir::Root => {
                            // Go to the root dir.
                            curr_dir = root.clone();
                        }
                        CdDir::Dir(dir_name) => {
                            let maybe_dir = curr_dir.borrow().get_dir(&dir_name);
                            match maybe_dir {
                                Some(dir) => {
                                    // Move to the dir.
                                    curr_dir = dir.clone()
                                }
                                None => {
                                    return Err(format!(
                                        "no entry for dir {} in {}",
                                        dir_name,
                                        curr_dir.borrow().name.clone()
                                    ))
                                }
                            }
                        }
                    },
                }
            }
            ParsedLine::Dir(dir_name) => {
                // Make sure we're in an ls
                //
                // Not sure this can happen; mostly a debug assert!
                if !in_ls {
                    return Err(format!("found dir entry {} when not in ls", dir_name,));
                }

                // Make sure there's not an existing entry for this dir.
                //
                // Not sure this can happen; mostly a debug assert!
                if let Some(_) = curr_dir.borrow().get_dir(&dir_name) {
                    return Err(format!(
                        "already have an entry for dir {} in {}",
                        dir_name,
                        curr_dir.borrow().name.clone()
                    ));
                }

                // Create a new dir entry and add it to the curr dir's set of dirs.
                let dir = Rc::new(RefCell::new(DirEntry::new(
                    Some(curr_dir.clone()),
                    &dir_name,
                )));
                curr_dir.borrow_mut().dirs.push(dir.clone());
            }
            ParsedLine::File(file_name, size) => {
                // Make sure we're in an ls
                //
                // Not sure this can happen; mostly a debug assert!
                if !in_ls {
                    return Err(format!("found file entry {} when not in ls", file_name));
                }

                // Create a new file entry and add it to the curr dir's set of files.
                let file = FileEntry {
                    name: file_name.clone(),
                    size,
                };
                curr_dir.borrow_mut().files.push(file);
            }
        }
    }

    Ok(root)
}

fn parse_line(line: &str) -> Result<ParsedLine, String> {
    let mut line_parts = line.trim_end_matches("\n").split(" ");

    Ok(match line_parts.next() {
        Some("$") => ParsedLine::Command(match line_parts.next() {
            Some("ls") => Command::Ls,
            Some("cd") => Command::Cd(match line_parts.next() {
                Some("..") => CdDir::Up,
                Some("/") => CdDir::Root,
                Some(dir) => CdDir::Dir(dir.into()),
                None => return Err("expected dir name".into()),
            }),
            Some(cmd) => return Err(format!("unexpected command {cmd}")),
            None => return Err("expected command name".into()),
        }),
        Some("dir") => match line_parts.next() {
            Some(dir_name) => ParsedLine::Dir(dir_name.into()),
            None => return Err("expected dir name".into()),
        },
        Some(part) => match u32::from_str_radix(part, 10) {
            Ok(size) => ParsedLine::File(
                line_parts
                    .next()
                    .ok_or(String::from("expected filename"))?
                    .into(),
                size,
            ),
            _ => return Err(format!("unexpected part {part} in line")),
        },
        None => return Err("unexpected empty line".into()),
    })
}

enum ParsedLine {
    Command(Command),
    Dir(String),
    File(String, u32),
}

enum Command {
    Ls,
    Cd(CdDir),
}

enum CdDir {
    Up,
    Root,
    Dir(String),
}

struct DirEntry {
    name: String,
    parent: Option<Rc<RefCell<DirEntry>>>,
    files: Vec<FileEntry>,
    dirs: Vec<Rc<RefCell<DirEntry>>>,
}

impl DirEntry {
    pub fn new(parent: Option<Rc<RefCell<DirEntry>>>, name: &str) -> Self {
        DirEntry {
            name: name.into(),
            parent,
            files: vec![],
            dirs: vec![],
        }
    }

    pub fn get_dir(self: &Self, dir_name: &str) -> Option<Rc<RefCell<DirEntry>>> {
        self.dirs
            .iter()
            .find(|dir| dir.borrow().name == dir_name)
            .map(|dir| dir.clone())
    }
}

struct FileEntry {
    name: String,
    size: u32,
}
