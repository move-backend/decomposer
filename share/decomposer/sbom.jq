. += {
    name: $name,
    SPDXID: "SPDXRef-\($name)", 
    dataLicense: "CC0-1.0",
    spdxVersion: "SPDX-2.2",
    comment: "This document was created using Decomposer \($version) using information from the declared git repos.",
    documentNamespace: ($namespace // "NOASSERTION"),
     creationInfo: {
        created: (now | todateiso8601),
        creators: ["Tool: Decomposer-\($version)"]
    },
    packages: ($packages | to_entries | map({
        SPDXID: "SPDXRef-\(.key)-\(.value.version)",
        name: .key,
        versionInfo: .value.version,
        copyrightText: "NOASSERTION",
        downloadLocation: (.value.url // "NOASSERTION"),
        licenseConcluded: "NOASSERTION",
        licenseDeclared: (.value.license // "NOASSERTION"),
        filesAnalyzed: false,
        sourceInfo: "Git checkout of the object \(.value.revision) from the repo",
        annotations: [
            {
                annotationDate: (now | todateiso8601),
                annotationType: "OTHER",
                annotator: "Tool: Decomposer-\($version)",
                comment: "Generated with checksum as commit hash"
            }
        ],
        checksums: [
            {algorithm: "SHA1", checksumValue: .value.commit}
        ]
    }))
}