package main

import (
    "fmt"
    "math/rand"
    "os"
    "testing"
)

func TestShredNonExist(t *testing.T) {
    filename := "non_exists"
    err := shred(filename)
    if err == nil {
        t.Errorf("shred should report errors if file doesn't exist'")
    }
}

func TestShred(t *testing.T) {
    filename := "testfile"
    if f, err := os.Create(filename); err != nil {
        panic(err)
    } else {
        var letters = []rune("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")

        n := rand.Intn(200)

        s := make([]rune, n)
        for i := range s {
            s[i] = letters[rand.Intn(len(letters))]
        }

        fmt.Fprintln(f, string(s))
        f.Close()
    }

    shred(filename)

    _, err := os.Stat(filename)
    if err == nil {
        t.Errorf("file not removed!")
    }
}
