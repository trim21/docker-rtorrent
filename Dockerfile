FROM nixos/nix:2.31.2

ENV NIX_CONFIG="experimental-features = nix-command flakes"

RUN nix profile add 'github:NixOS/nixpkgs/88946b891afcd227ff4b8186767c9b3fd45b0b9f#rtorrent' && \
    nix-collect-garbage

ENTRYPOINT ["/root/.nix-profile/bin/rtorrent"]
