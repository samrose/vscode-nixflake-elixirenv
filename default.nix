{ lib, pkgs }:

let
  basePackages = with pkgs; [alejandra bat beam.packages.erlangR25.elixir_1_14 docker-compose entr firefox gdal gnumake hivemind jq mix2nix nomad (postgresql_15.withPackages (p: [p.postgis])) graphviz imagemagick inotify-tools python3 tesseract unixtools.netstat ];

  myvscode = pkgs.vscode-with-extensions.override {
    vscodeExtensions = with pkgs.vscode-extensions; [
      ms-python.python
    ];
  };

in
{
  inherit basePackages;

  shell = pkgs.mkShell {
    buildInputs = basePackages ++ [ myvscode ];
    shellHook = ''
        source .env
        mkdir -p .nix-mix .nix-hex
        export MIX_HOME=$PWD/.nix-mix
        export HEX_HOME=$PWD/.nix-mix
        # make hex from Nixpkgs available
        # `mix local.hex` will install hex into MIX_HOME and should take precedence
        export PATH=$MIX_HOME/bin:$HEX_HOME/bin:$PATH
        export LANG=C.UTF-8
        # keep your shell history in iex
        export ERL_AFLAGS="-kernel shell_history enabled"
        # Postgres environment variables
        export PGDATA=$PWD/postgres_data
        export PGHOST=$PWD/postgres
        export LOG_PATH=$PWD/postgres/LOG
        export PGDATABASE=postgres
        export DATABASE_URL="postgresql:///postgres?host=$PGHOST&port=5434"
        if [ ! -d $PWD/postgres ]; then
          mkdir -p $PWD/postgres
        fi
        if [ ! -d $PGDATA ]; then
          echo 'Initializing postgresql database...'
          initdb $PGDATA --username $PGUSER -A md5 --pwfile=<(echo $PGPASS) --auth=trust >/dev/null
          echo "listen_addresses='*'" >> postgres_data/postgresql.conf
          echo "unix_socket_directories='$PWD/postgres'" >> postgres_data/postgresql.conf
          echo "unix_socket_permissions=0700" >> $PWD/postgres_data/postgresql.conf
        fi
        # #psql -p 5434 postgres -c 'create extension if not exists postgis' || true
        # # This creates mix variables and data folders within your project, so as not to pollute your system
        echo 'To run the services configured here, you can run the `hivemind` command'
      '';
  };
}
