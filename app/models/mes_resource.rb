module Mes
  module Elastic
    class Resource < Model
      config url: ENV['MES_ELASTICSEARCH_URL'], index: 'lte'
      multitype
    end
  end
end