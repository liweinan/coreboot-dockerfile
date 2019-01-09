docker build --force-rm -f Dockerfile.i386 -t firmware-build-i386 .
docker run -it firmware-build-i386 sh
