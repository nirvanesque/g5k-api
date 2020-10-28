class ApidocsController < ActionController::Base
  include Swagger::Blocks

  swagger_root do
    key :openapi, '3.0.0'
    info do
      key :version, '3.0'
      key :title, "Grid'5000 API"
      key :description, "Grid'5000 complete API"
      contact do
        key :name, 'support-staff@lists.grid5000.fr'
      end
      license do
        key :name, 'Apache 2.0'
      end
    end
    tag do
      key :name, 'reference-api'
      key :description, "Reference-api expose Grid'5000's reference-repository, "\
        "the single source of truth about sites, clusters, nodes, and network topology."
    end
    tag do
      key :name, 'status'
      key :description, "Status API allows tu known the state of OAR's resources "\
        "(like nodes, disks, vlans, subnets). The current and upcoming "\
        "reservations are also returned by this API."
    end
    server do
      key :url, 'https://api.grid5000.fr/3.0'
    end
  end

  swagger_component do
    parameter :deep do
      key :name, :deep
      key :in, :query
      key :description, 'Fetch a full view of reference-repository, under this path.'
      key :required, false
      key :type, :bool
    end

    parameter :version do
      key :name, :version
      key :in, :query
      key :description, "Specificy the reference-repository's commit hash to get. " \
        "This allow to get a specific version of the requested resource, to go back "\
        "in time."
      key :required, false
      key :type, :string
    end

    parameter :timestamp do
      key :name, :timestamp
      key :in, :query
      key :description, 'Fetch the version of reference-repository for the ' \
        'specified UNIX timestamp.'
      key :required, false
      key :type, :integer
    end

    parameter :date do
      key :name, :date
      key :in, :query
      key :description, 'Fetch the version of reference-repository for the ' \
        'specified date (ISO_8601 format).'
      key :required, false
      key :type, :string
      key :format, :'date-time'
    end

    parameter :branch do
      key :name, :branch
      key :in, :query
      key :description, "Use a specific branch of reference-repository, for example "\
        "the 'testing' branch contains the resources that are not yet in production."
      key :required, false
      key :type, :string
      key :default, 'master'
    end

    parameter :clusterId do
      key :name, :clusterId
      key :in, :path
      key :description, 'ID of cluster to fetch.'
      key :required, true
      key :type, :string
    end

    parameter :siteId do
      key :name, :siteId
      key :in, :path
      key :description, 'ID of site to fetch.'
      key :required, true
      key :type, :string
    end

    parameter :nodeId do
      key :name, :nodeId
      key :in, :path
      key :description, 'ID of node to fetch.'
      key :required, true
      key :type, :string
    end

    parameter :pduId do
      key :name, :pduId
      key :in, :path
      key :description, 'ID of pdu to fetch.'
      key :required, true
      key :type, :string
    end

    parameter :serverId do
      key :name, :serverId
      key :in, :path
      key :description, 'ID of server to fetch.'
      key :required, true
      key :type, :string
    end

    parameter :networkEquipmentId do
      key :name, :networkEquipmentId
      key :in, :path
      key :description, 'ID of network equipment to fetch.'
      key :required, true
      key :type, :string
    end

    parameter :statusDisks do
      key :name, :disks
      key :in, :query
      key :description, "Enable or disable status of disks in response. "\
        "Should be 'yes' or 'no'."
      key :required, false
      key :type, :string
      key :pattern, '^(no|yes)$'
      key :default, 'yes'
    end

    parameter :statusNodes do
      key :name, :nodes
      key :in, :query
      key :description, "Enable or disable status of nodes in response. "\
        "Should be 'yes' or 'no'."
      key :required, false
      key :type, :string
      key :pattern, '^(no|yes)$'
      key :default, 'yes'
    end

    parameter :statusVlans do
      key :name, :vlans
      key :in, :query
      key :description, "Enable or disable status of vlans in response. "\
        "Should be 'yes' or 'no'."
      key :required, false
      key :type, :string
      key :pattern, '^(no|yes)$'
      key :default, 'yes'
    end

    parameter :statusSubnets do
      key :name, :subnets
      key :in, :query
      key :description, "Enable or disable status of subnets in response. "\
        "Should be 'yes' or 'no'."
      key :required, false
      key :type, :string
      key :pattern, '^(no|yes)$'
      key :default, 'yes'
    end
  end

  # A list of all classes that have swagger_* declarations.
  SWAGGERED_CLASSES = [
    SitesController,
    ClustersController,
    ResourcesController,
    self
  ].freeze

  def index
    render json: Swagger::Blocks.build_root_json(SWAGGERED_CLASSES)
  end
end
