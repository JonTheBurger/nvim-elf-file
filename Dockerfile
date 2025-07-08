FROM nixos/nix
RUN mkdir -p /etc/nix && \
    echo "experimental-features = nix-command flakes" > /etc/nix/nix.conf
COPY flake.nix flake.lock /src/
WORKDIR /src
RUN nix develop --impure --command true
COPY . /src
ENTRYPOINT ["nix", "develop", "--impure", "--command"]
CMD ["bash"]
