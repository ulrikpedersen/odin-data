FROM centos:7 as base

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


FROM odin-dev as build

WORKDIR /src/

ARG BRANCH
RUN echo odin-data branch: ${BRANCH} &&\
    rm -rf odin-data && git clone -b ${BRANCH} https://github.com/ulrikpedersen/odin-data.git &&\
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
