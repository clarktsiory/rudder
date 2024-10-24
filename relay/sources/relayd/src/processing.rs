// SPDX-License-Identifier: GPL-3.0-or-later WITH GPL-3.0-linking-source-exception
// SPDX-FileCopyrightText: 2019-2020 Normation SAS

use std::{
    os::unix::prelude::OsStrExt,
    path::{Path, PathBuf},
};

use anyhow::Error;
use sha2::{Digest, Sha256};
use tokio::fs::{remove_file, rename};
use tracing::debug;

pub mod inventory;
pub mod reporting;
pub mod shared_files;

pub type ReceivedFile = PathBuf;
pub type RootDirectory = PathBuf;

#[derive(Debug, Copy, Clone)]
enum OutputError {
    Transient,
    Permanent,
}

impl From<Error> for OutputError {
    fn from(err: Error) -> Self {
        if let Some(_e) = err.downcast_ref::<diesel::result::Error>() {
            return OutputError::Transient;
        }
        if let Some(_e) = err.downcast_ref::<diesel::r2d2::PoolError>() {
            return OutputError::Transient;
        }
        if let Some(_e) = err.downcast_ref::<reqwest::Error>() {
            return OutputError::Transient;
        }

        OutputError::Permanent
    }
}

async fn success(file: ReceivedFile) -> Result<(), Error> {
    remove_file(file.clone())
        .await
        .map(move |_| debug!("deleted: {:#?}", file))?;
    Ok(())
}

async fn failure(file: ReceivedFile, directory: RootDirectory) -> Result<(), Error> {
    rename(
        file.clone(),
        directory
            .join("failed")
            .join(file.file_name().expect("not a file")),
    )
    .await?;

    debug!(
        "moved: {:#?} to {:#?}",
        file,
        directory
            .join("failed")
            .join(file.file_name().expect("not a file"))
    );
    Ok(())
}

/// Computes an id from a file name. It is added as key-value in tracing and allows following a file across relays
/// with a simple id.
/// It does not need to be cryptographic but only to have reasonable statistic quality, but we already have sha2 available
/// so why not.
pub fn queue_id_from_file(file: &Path) -> String {
    let mut hasher = Sha256::new();
    hasher.update(file.file_name().unwrap_or(file.as_os_str()).as_bytes());
    format!(
        // 32 chars is enough
        "{:.32X}",
        hasher.finalize()
    )
}
