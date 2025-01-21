# libvips on Amazon Linux 2023 AMI/Docker

At the time of creation libvips is not available on Amazon Linux 2023.
See [issue 295](https://github.com/amazonlinux/amazon-linux-2023/issues/295)


This repository is intended to provide a solution to build it on an AMI or Dockerfile.

The build is mostly intended to support widely used format on the web:

- jpg (via libjpeg-turbo)
- png (via spng)
- gif (via cgiflib)
- via (via libwebp)
- avif (via libheif)
- tiff (via libtiff)

in addition is using:

- SIMD support via [highway](https://github.com/google/highway)
- EXIF metadata support via [libexif](https://github.com/libexif/libexif)
- image quantisation with [libimagequant](https://github.com/ImageOptim/libimagequant)
- MagickCore

## Building

```
docker build -t libvips-al2023 -f Dockerfile --platform linux/amd64 .
```

# Running docker build

```
docker run -it --platform linux/amd64 --rm -v $(pwd -P):/tmp libvips-al2023
```

# Testing

