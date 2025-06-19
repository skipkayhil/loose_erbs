# frozen_string_literal: true

require "rails_helper"

class TestScanner < Minitest::Test
  def test_scanner_parses_renders_in_helpers
    scanner = LooseErbs::Scanner.new

    assert_equal ["components/_badge", "components/_shiny_badge"], scanner.renders
  end
end
