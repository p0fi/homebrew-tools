require "download_strategy"
require "json"

# Downloads a release asset from a *private* GitHub repository using
# HOMEBREW_GITHUB_API_TOKEN.
#
# The formula `url` is the normal browser download URL so Homebrew names the
# cached file with the correct `.tar.gz` extension and unpacks it. At fetch
# time we resolve that to the asset's API URL and download it with
# `Accept: application/octet-stream` -- the only reliable way to pull assets
# from a private repository (the browser URL 404s for private repos). GitHub
# then redirects to a pre-signed URL; Homebrew's curl uses `--location` (not
# `--location-trusted`), so the token is dropped on the cross-host redirect.
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
    curl_download asset_api_url,
                  "--header", "Accept: application/octet-stream",
                  "--header", "Authorization: token #{@github_token}",
                  to: temporary_path, timeout: timeout
  end

  def asset_api_url
    match = @url.match(%r{^https://github\.com/([^/]+)/([^/]+)/releases/download/([^/]+)/(.+)$})
    raise CurlDownloadStrategyError, "Unexpected GitHub release URL: #{@url}" if match.nil?

    owner, repo, tag, filename = match.captures
    metadata = curl_output(
      "--header", "Accept: application/vnd.github+json",
      "--header", "Authorization: token #{@github_token}",
      "https://api.github.com/repos/#{owner}/#{repo}/releases/tags/#{tag}"
    ).stdout
    asset = JSON.parse(metadata).fetch("assets", []).find { |a| a["name"] == filename }
    raise CurlDownloadStrategyError, "No asset named #{filename} in #{owner}/#{repo}@#{tag}" if asset.nil?

    asset.fetch("url")
  end
end

class Bopas < Formula
  desc "Automate SAP time-entry creation via the SAP Fiori form"
  homepage "https://github.com/p0fi/bopas"
  version "2026-11-13.2"
  license :cannot_represent

  on_macos do
    on_arm do
      url "https://github.com/p0fi/bopas/releases/download/#{version}/bopas_darwin_arm64.tar.gz",
          using: GitHubPrivateRepositoryReleaseDownloadStrategy
      sha256 "b9cc4ccce71c7178327fecfa219d1c7601db1f197174edd39264a6ce5afe557a"
    end
    on_intel do
      url "https://github.com/p0fi/bopas/releases/download/#{version}/bopas_darwin_amd64.tar.gz",
          using: GitHubPrivateRepositoryReleaseDownloadStrategy
      sha256 "0182d38379d4f2295c2e956ca7304766757b6419f5b92473828933165e411b7b"
    end
  end

  def install
    bin.install "bopas"
  end

  test do
    system bin/"bopas", "version"
  end
end
