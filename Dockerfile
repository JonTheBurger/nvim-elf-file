FROM nixos/nix
RUN mkdir -p /flake && \
    mkdir -p /etc/nix && \
    echo "experimental-features = nix-command flakes" > /etc/nix/nix.conf
WORKDIR /flake
COPY flake.nix /flake/flake.nix
COPY flake.lock /flake/flake.lock
RUN nix develop --impure --command true
WORKDIR /app
ENTRYPOINT ["nix", "develop", "--impure", "--command"]
CMD ["bash"]
