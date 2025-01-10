# frozen_string_literal: true

require "spec_helper"
require "formula"

describe Bundle::BrewInstaller do
  let(:formula) { "mysql" }
  let(:options) { { args: ["with-option"] } }
  let(:installer) { described_class.new(formula, options) }

  context "when the formula is installed" do
    before do
      allow_any_instance_of(described_class).to receive(:installed?).and_return(true)
    end

    context "with a true start_service option" do
      before do
        allow_any_instance_of(described_class).to receive(:install_change_state!).and_return(true)
        allow_any_instance_of(described_class).to receive(:installed?).and_return(true)
      end

      context "when service is already running" do
        before do
          allow(Bundle::BrewServices).to receive(:started?).with(formula).and_return(true)
        end

        context "with a successful installation" do
          it "start service" do
            expect(Bundle::BrewServices).not_to receive(:start)
            described_class.preinstall(formula, start_service: true)
            described_class.install(formula, start_service: true)
          end
        end

        context "with a skipped installation" do
          it "start service" do
            expect(Bundle::BrewServices).not_to receive(:start)
            described_class.install(formula, preinstall: false, start_service: true)
          end
        end
      end

      context "when service is not running" do
        before do
          allow(Bundle::BrewServices).to receive(:started?).with(formula).and_return(false)
        end

        context "with a successful installation" do
          it "start service" do
            expect(Bundle::BrewServices).to receive(:start).with(formula, verbose: false).and_return(true)
            described_class.preinstall(formula, start_service: true)
            described_class.install(formula, start_service: true)
          end
        end

        context "with a skipped installation" do
          it "start service" do
            expect(Bundle::BrewServices).to receive(:start).with(formula, verbose: false).and_return(true)
            described_class.install(formula, preinstall: false, start_service: true)
          end
        end
      end
    end

    context "with an always restart_service option" do
      before do
        allow_any_instance_of(described_class).to receive(:install_change_state!).and_return(true)
        allow_any_instance_of(described_class).to receive(:installed?).and_return(true)
      end

      context "with a successful installation" do
        it "restart service" do
          expect(Bundle::BrewServices).to receive(:restart).with(formula, verbose: false).and_return(true)
          described_class.preinstall(formula, restart_service: :always)
          described_class.install(formula, restart_service: :always)
        end
      end

      context "with a skipped installation" do
        it "restart service" do
          expect(Bundle::BrewServices).to receive(:restart).with(formula, verbose: false).and_return(true)
          described_class.install(formula, preinstall: false, restart_service: :always)
        end
      end
    end

    context "when the link option is true" do
      before do
        allow_any_instance_of(described_class).to receive(:install_change_state!).and_return(true)
      end

      it "links formula" do
        allow_any_instance_of(described_class).to receive(:linked?).and_return(false)
        expect(Bundle).to receive(:system).with(HOMEBREW_BREW_FILE, "link", "mysql",
                                                verbose: false).and_return(true)
        described_class.preinstall(formula, link: true)
        described_class.install(formula, link: true)
      end

      it "force-links keg-only formula" do
        allow_any_instance_of(described_class).to receive(:linked?).and_return(false)
        allow_any_instance_of(described_class).to receive(:keg_only?).and_return(true)
        expect(Bundle).to receive(:system).with(HOMEBREW_BREW_FILE, "link", "--force", "mysql",
                                                verbose: false).and_return(true)
        described_class.preinstall(formula, link: true)
        described_class.install(formula, link: true)
      end
    end

    context "when the link option is :overwrite" do
      before do
        allow_any_instance_of(described_class).to receive(:install_change_state!).and_return(true)
      end

      it "overwrite links formula" do
        allow_any_instance_of(described_class).to receive(:linked?).and_return(false)
        expect(Bundle).to receive(:system).with(HOMEBREW_BREW_FILE, "link", "--overwrite", "mysql",
                                                verbose: false).and_return(true)
        described_class.preinstall(formula, link: :overwrite)
        described_class.install(formula, link: :overwrite)
      end
    end

    context "when the link option is false" do
      before do
        allow_any_instance_of(described_class).to receive(:install_change_state!).and_return(true)
      end

      it "unlinks formula" do
        allow_any_instance_of(described_class).to receive(:linked?).and_return(true)
        expect(Bundle).to receive(:system).with(HOMEBREW_BREW_FILE, "unlink", "mysql",
                                                verbose: false).and_return(true)
        described_class.preinstall(formula, link: false)
        described_class.install(formula, link: false)
      end
    end

    context "when the link option is nil and formula is unlinked and not keg-only" do
      before do
        allow_any_instance_of(described_class).to receive(:install_change_state!).and_return(true)
        allow_any_instance_of(described_class).to receive(:linked?).and_return(false)
        allow_any_instance_of(described_class).to receive(:keg_only?).and_return(false)
      end

      it "links formula" do
        expect(Bundle).to receive(:system).with(HOMEBREW_BREW_FILE, "link", "mysql",
                                                verbose: false).and_return(true)
        described_class.preinstall(formula, link: nil)
        described_class.install(formula, link: nil)
      end
    end

    context "when the link option is nil and formula is linked and keg-only" do
      before do
        allow_any_instance_of(described_class).to receive(:install_change_state!).and_return(true)
        allow_any_instance_of(described_class).to receive(:linked?).and_return(true)
        allow_any_instance_of(described_class).to receive(:keg_only?).and_return(true)
      end

      it "unlinks formula" do
        expect(Bundle).to receive(:system).with(HOMEBREW_BREW_FILE, "unlink", "mysql",
                                                verbose: false).and_return(true)
        described_class.preinstall(formula, link: nil)

        described_class.install(formula, link: nil)
      end
    end

    context "when the conflicts_with option is provided" do
      before do
        allow(Bundle::BrewDumper).to receive(:formulae_by_full_name).and_return(
          name:           "mysql",
          conflicts_with: ["mysql55"],
        )
        allow(described_class).to receive(:formula_installed?).and_return(true)
        allow_any_instance_of(described_class).to receive(:install!).and_return(true)
        allow_any_instance_of(described_class).to receive(:upgrade!).and_return(true)
      end

      it "unlinks conflicts and stops their services" do
        verbose = false
        expect(Bundle).to receive(:system).with(HOMEBREW_BREW_FILE, "unlink", "mysql55",
                                                verbose:).and_return(true)
        expect(Bundle).to receive(:system).with(HOMEBREW_BREW_FILE, "unlink", "mysql56",
                                                verbose:).and_return(true)
        expect(Bundle::BrewServices).to receive(:stop).with("mysql55", verbose:).and_return(true)
        expect(Bundle::BrewServices).to receive(:stop).with("mysql56", verbose:).and_return(true)
        expect(Bundle::BrewServices).to receive(:restart).with(formula, verbose:).and_return(true)
        described_class.preinstall(formula, restart_service: :always, conflicts_with: ["mysql56"])
        described_class.install(formula, restart_service: :always, conflicts_with: ["mysql56"])
      end

      it "prints a message" do
        allow_any_instance_of(described_class).to receive(:puts)
        verbose = true
        expect(Bundle).to receive(:system).with(HOMEBREW_BREW_FILE, "unlink", "mysql55",
                                                verbose:).and_return(true)
        expect(Bundle).to receive(:system).with(HOMEBREW_BREW_FILE, "unlink", "mysql56",
                                                verbose:).and_return(true)
        expect(Bundle::BrewServices).to receive(:stop).with("mysql55", verbose:).and_return(true)
        expect(Bundle::BrewServices).to receive(:stop).with("mysql56", verbose:).and_return(true)
        expect(Bundle::BrewServices).to receive(:restart).with(formula, verbose:).and_return(true)
        described_class.preinstall(formula, restart_service: :always, conflicts_with: ["mysql56"], verbose: true)
        described_class.install(formula, restart_service: :always, conflicts_with: ["mysql56"], verbose: true)
      end
    end

    context "when the postinstall option is provided" do
      before do
        allow_any_instance_of(described_class).to receive(:install_change_state!).and_return(true)
        allow_any_instance_of(described_class).to receive(:installed?).and_return(true)
      end

      context "when formula has changed" do
        before do
          allow_any_instance_of(described_class).to receive(:changed?).and_return(true)
        end

        it "runs the postinstall command" do
          expect(Bundle).to receive(:system).with("custom command", verbose: false).and_return(true)
          described_class.preinstall(formula, postinstall: "custom command")
          described_class.install(formula, postinstall: "custom command")
        end

        it "reports a failure" do
          expect(Bundle).to receive(:system).with("custom command", verbose: false).and_return(false)
          described_class.preinstall(formula, postinstall: "custom command")
          expect(described_class.install(formula, postinstall: "custom command")).to be(false)
        end
      end

      context "when formula has not changed" do
        before do
          allow_any_instance_of(described_class).to receive(:changed?).and_return(false)
        end

        it "does not run the postinstall command" do
          expect(Bundle).not_to receive(:system)
          described_class.preinstall(formula, postinstall: "custom command")
          described_class.install(formula, postinstall: "custom command")
        end
      end
    end
  end

  context "when a formula isn't installed" do
    before do
      allow_any_instance_of(described_class).to receive(:installed?).and_return(false)
      allow_any_instance_of(described_class).to receive(:install_change_state!).and_return(false)
    end

    it "did not call restart service" do
      expect(Bundle::BrewServices).not_to receive(:restart)
      described_class.preinstall(formula, restart_service: true)
    end
  end

  describe ".outdated_formulae" do
    it "calls Homebrew" do
      described_class.reset!
      expect(Bundle::BrewDumper).to receive(:formulae).and_return(
        [
          { name: "a", outdated?: true },
          { name: "b", outdated?: true },
          { name: "c", outdated?: false },
        ],
      )
      expect(described_class.outdated_formulae).to eql(%w[a b])
    end
  end

  describe ".pinned_formulae" do
    it "calls Homebrew" do
      described_class.reset!
      expect(Bundle::BrewDumper).to receive(:formulae).and_return(
        [
          { name: "a", pinned?: true },
          { name: "b", pinned?: true },
          { name: "c", pinned?: false },
        ],
      )
      expect(described_class.pinned_formulae).to eql(%w[a b])
    end
  end

  describe ".formula_installed_and_up_to_date?" do
    before do
      Bundle::BrewDumper.reset!
      described_class.reset!
      allow(described_class).to receive(:outdated_formulae).and_return(%w[bar])
      allow_any_instance_of(Formula).to receive(:outdated?).and_return(true)
      allow(Bundle::BrewDumper).to receive(:formulae).and_return [
        {
          name:         "foo",
          full_name:    "homebrew/tap/foo",
          aliases:      ["foobar"],
          args:         [],
          version:      "1.0",
          dependencies: [],
          requirements: [],
        },
        {
          name:         "bar",
          full_name:    "bar",
          aliases:      [],
          args:         [],
          version:      "1.0",
          dependencies: [],
          requirements: [],
        },
      ]
    end

    it "returns result" do
      expect(described_class.formula_installed_and_up_to_date?("foo")).to be(true)
      expect(described_class.formula_installed_and_up_to_date?("foobar")).to be(true)
      expect(described_class.formula_installed_and_up_to_date?("bar")).to be(false)
      expect(described_class.formula_installed_and_up_to_date?("baz")).to be(false)
    end
  end

  context "when brew is installed" do
    context "when no formula is installed" do
      before do
        allow(described_class).to receive(:installed_formulae).and_return([])
        allow_any_instance_of(described_class).to receive(:conflicts_with).and_return([])
      end

      it "install formula" do
        expect(Bundle).to receive(:system)
          .with(HOMEBREW_BREW_FILE, "install", "--formula", formula, "--with-option", verbose: false)
          .and_return(true)
        expect(installer.preinstall).to be(true)
        expect(installer.install).to be(true)
      end

      it "reports a failure" do
        expect(Bundle).to receive(:system)
          .with(HOMEBREW_BREW_FILE, "install", "--formula", formula, "--with-option", verbose: false)
          .and_return(false)
        expect(installer.preinstall).to be(true)
        expect(installer.install).to be(false)
      end
    end

    context "when formula is installed" do
      before do
        allow(described_class).to receive(:installed_formulae).and_return([formula])
        allow_any_instance_of(described_class).to receive(:conflicts_with).and_return([])
        allow_any_instance_of(Formula).to receive(:outdated?).and_return(true)
      end

      context "when formula upgradable" do
        before do
          allow(described_class).to receive(:outdated_formulae).and_return([formula])
        end

        it "upgrade formula" do
          expect(Bundle).to receive(:system).with(HOMEBREW_BREW_FILE, "upgrade", "--formula", formula, verbose: false)
                                            .and_return(true)
          expect(installer.preinstall).to be(true)
          expect(installer.install).to be(true)
        end

        it "reports a failure" do
          expect(Bundle).to receive(:system).with(HOMEBREW_BREW_FILE, "upgrade", "--formula", formula, verbose: false)
                                            .and_return(false)
          expect(installer.preinstall).to be(true)
          expect(installer.install).to be(false)
        end

        context "when formula pinned" do
          before do
            allow(described_class).to receive(:pinned_formulae).and_return([formula])
          end

          it "does not upgrade formula" do
            expect(Bundle).not_to receive(:system).with(HOMEBREW_BREW_FILE, "upgrade", "--formula", formula,
                                                        verbose: false)
            expect(installer.preinstall).to be(false)
          end
        end

        context "when formula not upgraded" do
          before do
            allow(described_class).to receive(:outdated_formulae).and_return([])
          end

          it "does not upgrade formula" do
            expect(Bundle).not_to receive(:system)
            expect(installer.preinstall).to be(false)
          end
        end
      end
    end
  end

  describe "#changed?" do
    it "is false by default" do
      expect(described_class.new(formula).changed?).to be(false)
    end
  end

  describe "#start_service?" do
    it "is false by default" do
      expect(described_class.new(formula).start_service?).to be(false)
    end

    context "when the start_service option is true" do
      it "is true" do
        expect(described_class.new(formula, start_service: true).start_service?).to be(true)
      end
    end
  end

  describe "#start_service_needed?" do
    context "when a service is already started" do
      before do
        allow(Bundle::BrewServices).to receive(:started?).with(formula).and_return(true)
      end

      it "is false by default" do
        expect(described_class.new(formula).start_service_needed?).to be(false)
      end

      it "is false with {start_service: true}" do
        expect(described_class.new(formula, start_service: true).start_service_needed?).to be(false)
      end

      it "is false with {restart_service: true}" do
        expect(described_class.new(formula, restart_service: true).start_service_needed?).to be(false)
      end

      it "is false with {restart_service: :changed}" do
        expect(described_class.new(formula, restart_service: :changed).start_service_needed?).to be(false)
      end

      it "is false with {restart_service: :always}" do
        expect(described_class.new(formula, restart_service: :always).start_service_needed?).to be(false)
      end
    end

    context "when a service is not started" do
      before do
        allow(Bundle::BrewServices).to receive(:started?).with(formula).and_return(false)
      end

      it "is false by default" do
        expect(described_class.new(formula).start_service_needed?).to be(false)
      end

      it "is true if {start_service: true}" do
        expect(described_class.new(formula, start_service: true).start_service_needed?).to be(true)
      end

      it "is true if {restart_service: true}" do
        expect(described_class.new(formula, restart_service: true).start_service_needed?).to be(true)
      end

      it "is true if {restart_service: :changed}" do
        expect(described_class.new(formula, restart_service: :changed).start_service_needed?).to be(true)
      end

      it "is true if {restart_service: :always}" do
        expect(described_class.new(formula, restart_service: :always).start_service_needed?).to be(true)
      end
    end
  end

  describe "#restart_service?" do
    it "is false by default" do
      expect(described_class.new(formula).restart_service?).to be(false)
    end

    context "when the restart_service option is true" do
      it "is true" do
        expect(described_class.new(formula, restart_service: true).restart_service?).to be(true)
      end
    end

    context "when the restart_service option is always" do
      it "is true" do
        expect(described_class.new(formula, restart_service: :always).restart_service?).to be(true)
      end
    end

    context "when the restart_service option is changed" do
      it "is true" do
        expect(described_class.new(formula, restart_service: :changed).restart_service?).to be(true)
      end
    end
  end

  describe "#restart_service_needed?" do
    it "is false by default" do
      expect(described_class.new(formula).restart_service_needed?).to be(false)
    end

    context "when a service is unchanged" do
      before do
        allow_any_instance_of(described_class).to receive(:changed?).and_return(false)
      end

      it "is false with {restart_service: true}" do
        expect(described_class.new(formula, restart_service: true).restart_service_needed?).to be(false)
      end

      it "is true with {restart_service: :always}" do
        expect(described_class.new(formula, restart_service: :always).restart_service_needed?).to be(true)
      end

      it "is false if {restart_service: :changed}" do
        expect(described_class.new(formula, restart_service: :changed).restart_service_needed?).to be(false)
      end
    end

    context "when a service is changed" do
      before do
        allow_any_instance_of(described_class).to receive(:changed?).and_return(true)
      end

      it "is true with {restart_service: true}" do
        expect(described_class.new(formula, restart_service: true).restart_service_needed?).to be(true)
      end

      it "is true with {restart_service: :always}" do
        expect(described_class.new(formula, restart_service: :always).restart_service_needed?).to be(true)
      end

      it "is true if {restart_service: :changed}" do
        expect(described_class.new(formula, restart_service: :changed).restart_service_needed?).to be(true)
      end
    end
  end
end
