# frozen_string_literal: true

require 'spec_helper'

RSpec.describe OnlyofficeLanguageHelper::DetectLanguageWrapper do
  it 'get list of all languages' do
    expect(OnlyofficeLanguageHelper::DetectLanguageWrapper.all_languages).to be_a(Array)
  end

  it 'check word for language' do
    expect(OnlyofficeLanguageHelper::DetectLanguageWrapper.detect_language('Buongiorno').first['language']).to eq('it')
  end
end
