cask "dcld" do
  version "1.5.1"

  on_macos do
    on_arm do
      sha256 "5f6ba74b8e34ad2bfd8833075d36a04e9ccc9b0fac38141f5aea040b609c9487"
      url "https://github.com/zigbee-alliance/distributed-compliance-ledger/releases/download/v#{version}/dcld.macos.tar.gz"
    end
  end

  name "dcld"
  desc "CLI and full node for the Zigbee Alliance Distributed Compliance Ledger"
  homepage "https://github.com/zigbee-alliance/distributed-compliance-ledger"

  livecheck do
    url "https://github.com/zigbee-alliance/distributed-compliance-ledger"
    strategy :github_latest
  end

  binary "dcld"

  postflight do
    system_command "/usr/bin/xattr", args: ["-dr", "com.apple.quarantine", "#{staged_path}/dcld"]
  end
end
