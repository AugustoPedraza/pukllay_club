defmodule PukllayClubWeb.ClubLinksTest do
  @moduledoc """
  `public_phone/0` assertions (D-02, SEO-06) — a pure-module test, no
  connection/DB needed.
  """

  use ExUnit.Case, async: true

  alias PukllayClubWeb.ClubLinks

  @club_links_source_path Path.join([File.cwd!(), "lib", "pukllay_club_web", "club_links.ex"])
  @deploy_yml_path Path.join([File.cwd!(), "config", "deploy.yml"])

  describe "public_phone/0 (D-02, SEO-06)" do
    test "returns a non-empty, plus-prefixed international-format string" do
      phone = ClubLinks.public_phone()

      assert is_binary(phone)
      refute phone == ""
      assert String.starts_with?(phone, "+")
    end

    test "its digits equal the reservation number declared in config/deploy.yml" do
      deploy_yml = File.read!(@deploy_yml_path)

      [_, reservation_number] = Regex.run(~r/RESERVATION_WHATSAPP_NUMBER:\s*"(\d+)"/, deploy_yml)

      digits_only = String.replace(ClubLinks.public_phone(), ~r/\D/, "")

      assert digits_only == reservation_number
    end

    test "the moduledoc still forbids resolving RESERVATION_WHATSAPP_NUMBER through this module" do
      source = File.read!(@club_links_source_path)

      assert source =~ "must never be resolved through this module"
    end

    test "the moduledoc documents public_phone/0 alongside the existing entries" do
      source = File.read!(@club_links_source_path)

      assert source =~ "public_phone/0"
    end
  end
end
