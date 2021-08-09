** Zig program accessing Postgresql using libpq C library **

* Docker to run postgresql to test this program. 
Open a terminal window an run ...
```bash
$ docker-compose up
```

* Install libpq ( in macosx ).
```bash
$ brew install libpq
```

* Setup useful environment variables.

```bash
$ export ZIG_SYSTEM_LINKER_HACK=1
```

* Install zig using asdf ( how to install asdf is out of this scope )

```bash
$ asdf install zig 0.8.0
```

* Compile this program

```bash
$ zig build-exe -lc -l pq -L/usr/local/Cellar/libpq/13.3/lib/ -I/usr/local/Cellar/libpq/13.3/include zig-pg-demo.zig
```

* Run the program
```bash
$ ./zig-pg-demo 127.0.0.1 25432 postgres postgres postgres
```

