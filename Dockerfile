# README - how to use this file
# In order to build the docker images for development (i.e. build stage) or
# the light-weight run-time image (i.e. run stage) you must map a local copy
# of the odin-data sources into the image /src/odin-data 
# This is achieved by adding a copy of the host . dir into the image in /src/odin-data/
# When running the development image (build stage) you must map the host odin-data dir
# into /src/odin-data/ using the -v flag to docker run.

FROM centos:7 as build

# Set the working directory to /app
WORKDIR /src

RUN yum -y update && yum -y clean all &&\
    yum groupinstall -y 'Development Tools' &&\
    yum install -y boost boost-devel cmake log4cxx-devel epel-release &&\
    yum install -y zeromq3-devel python2-pip &&\
    yum -y clean all && rm -rf /var/cache/yum &&\
    cd /src/ &&\
        curl -L -O https://www.hdfgroup.org/ftp/HDF5/releases/hdf5-1.10/hdf5-1.10.1/src/hdf5-1.10.1.tar.bz2 &&\
        tar -jxf hdf5-1.10.1.tar.bz2 &&\
        mkdir -p /src/build-hdf5-1.10 && cd /src/build-hdf5-1.10 &&\
        /src/hdf5-1.10.1/configure --prefix=/usr/local && make >> /src/hdf5build.log 2>&1 && make install &&\
    cd /src/ &&\
        curl -L -s -o c-blosc-1.14.2.tar.gz -O https://github.com/Blosc/c-blosc/archive/v1.14.2.tar.gz &&\
        tar -zxf c-blosc-1.14.2.tar.gz &&\
        mkdir -p /src/build-blosc && cd /src/build-blosc &&\
        cmake /src/c-blosc-1.14.2/ && make >> /src/bloscbuild.log 2>&1 && make install &&\
    cd / && rm -rf /src/build* /src/*.tar*


WORKDIR /src/

# Copy the host . dir into src/odin-data
ADD . /src/odin-data

RUN git --git-dir=/src/odin-data/.git --work-tree=/src/odin-data/ branch &&\
    git --git-dir=/src/odin-data/.git --work-tree=/src/odin-data/ remote -v &&\
    mkdir -p /src/build-odin-data && cd /src/build-odin-data &&\
    cmake /src/odin-data/ &&\
    make &&\
    ./bin/frameReceiverTest &&\
    ./bin/frameProcessorTest &&\
    make package && mv *.rpm .. && cd .. &&\
    yum -y localinstall odin-data*.rpm &&\
    rm -rf odin-data/.git/ &&\
    rm -rf /src/build*


FROM centos:7 as run

WORKDIR /root
COPY --from=build /src/odin-data*.rpm /root/
COPY --from=build /usr/local/ /usr/local/
RUN yum -y update &&\
    yum -y install epel-release &&\
    yum -y localinstall odin-data*.rpm &&\
    yum -y clean all && rm -rf /var/cache/yum
