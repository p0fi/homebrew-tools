require "download_strategy"

# Downloads a release asset from a private GitHub repository, authenticating
# with HOMEBREW_GITHUB_API_TOKEN. GitHub authorizes the request and redirects
# to a pre-signed asset URL; Homebrew's curl uses --location (not
# --location-trusted), so the token is correctly dropped on the redirect.
class GitHubPrivateRepositoryReleaseDownloadStrategy < CurlDownloadStrategy
  def initialize(url, name, version, **meta)
    super
    @github_token = ENV.fetch("HOMEBREW_GITHUB_API_TOKEN", nil)
    return if @github_token.present?

    raise CurlDownloadStrategyError,
          "HOMEBREW_GITHUB_API_TOKEN is required to install #{name} from its private repository."
  end

  private

  def _fetch(url:, resolved_url:, timeout:)
    curl_download url,
                  "--header", "Authorization: token #{@github_token}",
                  to: temporary_path, timeout: timeout
  end
end

class Bopas < Formula
  desc "Automate SAP time-entry creation via the SAP Fiori form"
  homepage "https://github.com/p0fi/bopas"
  version "2026-06-15"
  license :cannot_represent

  on_macos do
    on_arm do
      url "https://github.com/p0fi/bopas/releases/download/#{version}/bopas_darwin_arm64.tar.gz",
          using: GitHubPrivateRepositoryReleaseDownloadStrategy
      sha256 "f808b854876511d41913ae80a32582a426d7263d61b832ec8793dbbf3c136647"
    end
    on_intel do
      url "https://github.com/p0fi/bopas/releases/download/#{version}/bopas_darwin_amd64.tar.gz",
          using: GitHubPrivateRepositoryReleaseDownloadStrategy
      sha256 "03e263ef1e4e2d84b67947679ad2b84ea0d98da0ef092903e1aaeb5cbfca9f82"
    end
  end

  def install
    bin.install "bopas"
  end

  test do
    system bin/"bopas", "version"
  end
end
