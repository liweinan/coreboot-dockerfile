docker build --force-rm -f Dockerfile.deps -t weli/build-machine-deps .
docker build --force-rm -f Dockerfile.i386 -t weli/build-machine-i386 .