package main

import (
	"client/pkg/customer"
	"client/pkg/run"

	"github.com/alecthomas/kong"
)

var cli struct {
	Customer customer.Cmd `cmd:"" help:"Customer admin"`

	Run run.Cmd `cmd:"" help:"Start app"`
}

func main() {
	ctx := kong.Parse(&cli,
		kong.UsageOnError(),
		kong.ConfigureHelp(kong.HelpOptions{Compact: true}),
	)
	ctx.FatalIfErrorf(ctx.Run())
}
