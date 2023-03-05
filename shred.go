// shred in go
package main

import (
    "crypto/rand"
    "os"
)

func overwrite(filename string) error {
    f, err := os.OpenFile(filename, os.O_WRONLY, 0)
    if err != nil {
        return err
    }

    defer f.Close()

    info, err := f.Stat()
    if err != nil {
        return err
    }

    buff := make([]byte, info.Size())
    if _, err := rand.Read(buff); err != nil {
        return err
    }

    _, err = f.WriteAt(buff, 0)
    return err
}

func remove(filename string) error {
    if err := os.Remove(filename); err != nil {
        return err
    }

    return nil
}

func shred(filename string) error {
    // overwrite the file with random data for 3 times
    n := 3
    for i := 0; i < n; i++ {
        if err := overwrite(filename); err != nil {
            return err
        }
    }

    // remove the file
    return remove(filename)
}
