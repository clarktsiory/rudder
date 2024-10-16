// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2023 Normation SAS

//! Technique test definition
//!
//! Techniques can contain tests cases in a `tests` folder.
//!
//! `Rudderc` reads all `.yml` files in the `tests` folders as test definitions.
//!
//! NOTE:
//! We try to stay close to the GitHub Actions and Gitlab CI logic and syntax when it makes sense.

// Test file specifications. Do we want several test cases in one file?

use std::{
    collections::{HashMap, HashSet},
    path::Path,
    process::Command,
};

use anyhow::{bail, Result};
use rudder_commons::logs::ok_output;
use serde::{Deserialize, Serialize};

#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize)]
pub struct Step {
    #[serde(rename = "sh")]
    command: String,
}

#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize)]
pub struct TestCase {
    /// Parameters, we don't actually use them as they're loaded directly by the technique
    #[serde(rename = "params")]
    #[serde(default)]
    parameters: HashMap<String, String>,
    /// Conditions to define before running the test
    #[serde(default)]
    conditions: HashSet<String>,
    /// Test setup steps
    #[serde(default)]
    setup: Vec<Step>,
    /// Check test after
    check: Vec<Step>,
}

impl TestCase {
    fn run(step: &Step, dir: &Path) -> Result<()> {
        ok_output("Running", format!("'{}'", &step.command));
        let output = Command::new("/bin/sh")
            .arg("-c")
            .arg(&step.command)
            .current_dir(dir)
            .output()?;
        if !output.status.success() {
            bail!(
                "Test '{}' failed\nstdout: {}\nstderr: {}",
                &step.command,
                String::from_utf8(output.stdout)?,
                String::from_utf8(output.stderr)?,
            )
        }
        Ok(())
    }

    pub fn setup(&self, dir: &Path) -> Result<()> {
        for s in &self.setup {
            Self::run(s, dir)?;
        }
        Ok(())
    }

    pub fn check(&self, dir: &Path) -> Result<()> {
        for s in &self.check {
            Self::run(s, dir)?;
        }
        Ok(())
    }
}
