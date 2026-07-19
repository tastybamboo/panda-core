# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::Core::ModuleRegistry::JavaScriptMiddleware do
  let(:downstream_app) { ->(env) { [404, {"Content-Type" => "text/plain"}, ["Not Found"]] } }
  let(:tmp_dir) { Rails.root.join("tmp/js_middleware_test") }

  subject(:middleware) { described_class.new(downstream_app) }

  before { FileUtils.mkdir_p(tmp_dir) }
  after { FileUtils.rm_rf(tmp_dir) }

  # `find_javascript_file` walks ModuleRegistry's registered engines, which
  # is exercised elsewhere (navigation_registry_spec.rb et al) — stubbing it
  # directly here isolates `serve_file`'s content-type behaviour, the thing
  # this spec cares about, from the module/engine-resolution machinery.
  def serve(path, file_path)
    allow(middleware).to receive(:find_javascript_file).and_return(file_path.to_s)
    env = Rack::MockRequest.env_for(path)
    middleware.call(env)
  end

  it "serves .mjs as a JS content type, not text/plain" do
    file = tmp_dir.join("module.mjs")
    File.write(file, "export const x = 1;")

    _status, headers, body = serve("/panda/core/module.mjs", file)

    expect(headers["Content-Type"]).to eq("application/javascript; charset=utf-8")
    expect(body.first).to eq("export const x = 1;")
  end

  it "still serves .js as application/javascript (unchanged behaviour)" do
    file = tmp_dir.join("script.js")
    File.write(file, "console.log(1);")

    _status, headers, = serve("/panda/core/script.js", file)

    expect(headers["Content-Type"]).to eq("application/javascript; charset=utf-8")
  end

  it "still serves .json as application/json (unchanged behaviour)" do
    file = tmp_dir.join("data.json")
    File.write(file, "{}")

    _status, headers, = serve("/panda/core/data.json", file)

    expect(headers["Content-Type"]).to eq("application/json; charset=utf-8")
  end

  it "passes through paths outside /panda/ to the downstream app" do
    status, = middleware.call(Rack::MockRequest.env_for("/other/path.mjs"))

    expect(status).to eq(404)
  end
end
