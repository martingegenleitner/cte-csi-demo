package main

// This code is shamelessly stolen from...
// * https://github.com/kataras/iris/blob/master/_examples/file-server/upload-file/main.go
// * https://github.com/kataras/iris/blob/master/_examples/file-server/basic/main.go
// * https://www.iris-go.com/docs/#/?id=single-file

import (
	"crypto/md5"
	"fmt"
	"io"
	"path/filepath"
	"strconv"
	"time"

	"github.com/kataras/iris/v12"
)

const maxSize = 5 << 20 // 5MB

func main() {
	app := iris.New()

	app.RegisterView(iris.HTML("./templates", ".html"))

	// Serve the upload_form.html to the client.
	app.Get("/upload", func(ctx iris.Context) {
		// create a token (optionally).

		now := time.Now().Unix()
		h := md5.New()
		io.WriteString(h, strconv.FormatInt(now, 10))
		token := fmt.Sprintf("%x", h.Sum(nil))

		// render the form with the token for any use you'd like.
		// ctx.ViewData("", token)
		// or add second argument to the `View` method.
		// Token will be passed as {{.}} in the template.
		ctx.View("upload_form.html", token)
	})

	// Serve the index.html to the client.
	app.Get("/", func(ctx iris.Context) {
		ctx.View("index.html")
	})

	app.HandleDir("/uploads", iris.Dir("./upload"))

	// Handle the post request from the upload_form.html to the server
	app.Post("/upload", iris.LimitRequestBodySize(maxSize+1<<20), func(ctx iris.Context) {
		// Get the file from the request.
		f, fh, err := ctx.FormFile("uploadfile")
		if err != nil {
			ctx.StatusCode(iris.StatusInternalServerError)
			ctx.HTML("Error while uploading: <b>" + err.Error() + "</b>")
			return
		}
		defer f.Close()

		_, err = ctx.SaveFormFile(fh, filepath.Join("./upload", "photo.jpeg"))
		if err != nil {
			ctx.StatusCode(iris.StatusInternalServerError)
			ctx.HTML("Error while uploading: <b>" + err.Error() + "</b>")
			return
		}
	})

	// start the server at http://localhost:8080 with post limit at 5 MB.
	app.Listen(":80" /* 0.*/, iris.WithPostMaxMemory(maxSize))
}
