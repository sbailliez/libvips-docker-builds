# libvips on Amazon Linux 2023 AMI/Docker

At the time of creation [libvips](https://github.com/libvips/libvips) is not available on Amazon Linux 2023.
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

## AMI / EC2

## Building

To build directly on an EC2 instance, just get `install-libvips` script and use it on your instance.

```shell
chmod +x ./install-libvips.sh
sudo ./install-libvips.sh
```

## Running

Check that `vips` is installed properly (in `/usr/local/bin`) and that the configuration is appropriate:

```shell
vips -v && vips --vips-config
```


## Docker

### Building

```shell
docker build -t libvips-al2023 -f Dockerfile --platform linux/amd64 .
```

## Running docker build

```shell
docker run -it --platform linux/amd64 --rm -v $(pwd -P):/tmp libvips-al2023
```

## Testing

