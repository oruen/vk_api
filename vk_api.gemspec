# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "vk_api/version"

Gem::Specification.new do |s|
  s.name        = "vk_api"
  s.version     = VkApi::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Nikolay Karev", "Nick Recobra"]
  s.email       = ["oruenu@gmail.com"]
  s.homepage    = "https://github.com/oruen/vk_api"
  s.summary     = %q{Гем для общения с Open API сайта ВКонтакте}
  s.description = %q{Гем для общения с Open API сайта ВКонтакте без использования пользовательских сессий.}

  s.rubyforge_project = "vk_api"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
