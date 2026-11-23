// Regenerate the SVGs from this directory:
//   docker run --rm -v "$PWD:/work" -w /work structurizr/structurizr export -workspace workspace.dsl -format plantuml -output exports
//   docker run --rm -v "$PWD/exports:/data" -w /data plantuml/plantuml -tsvg "structurizr-*.puml"
workspace "Cell platform" "The recommended design: Crossplane renders one cell per team, and the Argo CD hub ships each cell to every workload cluster." {

    !identifiers hierarchical

    model {
        platformTeam = person "Platform team" "Owns the Cell template and every fence."
        tenantTeam = person "Tenant team" "Owns the workloads in its cell. Cannot edit the fences."
        client = person "Internet client" "Calls a public cell."

        teamAccounts = softwareSystem "Team AWS accounts" "One account per team. Hold that team's Postgres and DynamoDB." "External"
        thirdParty = softwareSystem "Third-party APIs" "Services outside the platform that a cell is allowed to call." "External"

        platform = softwareSystem "Cell platform" "Gives each team a cell: namespaces, network fences, gateway attachment, and data stores." {
            git = container "Git repository" "Holds the Cell XRs and the Compositions. A revision is labelled dev, then stable." "Git"
            argo = container "Argo CD hub" "Ships each Cell XR to every workload cluster." "Argo CD ApplicationSet"
            crossplane = container "Crossplane" "Runs on each workload cluster. Renders cells and data stores. Dev clusters take every revision, prod clusters take stable ones." "Crossplane 2.4, composition functions"
            cell = container "Cell" "One team's namespaces, its waypoint, and its fences. The waypoint is the only way in." "Istio ambient, Cilium"
            gateway = container "Regional gateway" "The north door. One ListenerSet per public cell." "Gateway API"
            egress = container "Egress waypoint" "The south door. Adds API keys for third parties." "Istio ambient, kgateway"
        }

        platformTeam -> platform.git "Edits the template and labels revisions" "Pull request"
        platform.argo -> platform.git "Reads Cell XRs"
        platform.argo -> platform.crossplane "Applies Cell XRs"
        platform.crossplane -> platform.cell "Renders namespaces, the waypoint, and the fences"
        platform.crossplane -> teamAccounts "Provisions data stores by assuming one role per account" "AWS API"
        tenantTeam -> platform.cell "Deploys workloads" "Helm chart"
        client -> platform.gateway "Sends north traffic" "HTTPS"
        platform.gateway -> platform.cell "Routes through the cell's waypoint" "HBONE"
        platform.cell -> platform.cell "Calls declared dependencies through their waypoints" "East and west traffic"
        platform.cell -> platform.egress "Sends south traffic"
        platform.egress -> thirdParty "Calls with an injected API key" "HTTPS"
        platform.cell -> teamAccounts "Reads and writes its data"
    }

    views {
        systemContext platform "Context" "Who uses the platform and what it depends on." {
            include *
            autolayout lr
        }
        container platform "Containers" "How a cell is delivered and how traffic reaches it." {
            include *
            autolayout lr
        }
        styles {
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
        }
    }
}
