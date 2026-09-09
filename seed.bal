// Seed data: registered institutions and a handful of assets across campuses,
// loaded at service start-up so every endpoint has something to show.

function loadSeedData() returns error? {
    Institution[] seedInstitutions = [
        {name: "Namibia University of Science and Technology", location: "Windhoek"},
        {name: "University of Namibia", location: "Windhoek"},
        {name: "International University of Management", location: "Windhoek"}
    ];
    foreach var institution in seedInstitutions {
        institutions[institution.name] = institution;
    }

    Asset[] seedAssets = [
        {
            assetTag: "NUST-LIB-3DP-001",
            name: "Pro-Series 3D Printer",
            description: "High-precision laboratory printer for simulation and prototype development.",
            institution: "Namibia University of Science and Technology",
            site: "Main Campus - Innovation Lab",
            status: AVAILABLE,
            dateAcquired: "2024-03-10",
            components: [
                {compId: "C101", name: "High-Torque Stepper Motor",
                 description: "Main motor for X-axis movement."}
            ],
            schedules: [
                {scheduleId: "SCH-882", 'type: MAINTENANCE, dueDate: "2026-09-01",
                 description: "Quarterly calibration and nozzle cleaning."}
            ],
            workOrders: [
                {orderId: "WO-554", status: OPEN,
                 description: "Nozzle heat-bed failure",
                 tasks: [{taskId: "T1", description: "Check thermal sensor connectivity."}]}
            ]
        },
        {
            assetTag: "NUST-LIB-LAP-014",
            name: "Dell Latitude 5540",
            description: "Student loan laptop, 16GB RAM.",
            institution: "Namibia University of Science and Technology",
            site: "Main Campus - Library",
            status: LOANED_OUT,
            dateAcquired: "2025-01-20",
            schedules: [
                {scheduleId: "SCH-901", 'type: SERVICING, dueDate: "2027-01-15",
                 description: "Annual hardware service and battery check."}
            ]
        },
        {
            assetTag: "UNAM-LIB-ROOM-101",
            name: "Meeting Room 101",
            description: "12-seat meeting room with projector and whiteboard.",
            institution: "University of Namibia",
            site: "Main Campus - Library Wing",
            status: AVAILABLE,
            dateAcquired: "2023-08-01",
            schedules: [
                {scheduleId: "SCH-770", 'type: BOOKING, dueDate: "2026-09-10",
                 description: "Research group weekly meeting."}
            ]
        },
        {
            assetTag: "UNAM-LAB-PC-220",
            name: "Thin Client TC-440",
            description: "Lab thin client terminal, row 2.",
            institution: "University of Namibia",
            site: "Science Campus - Computer Lab 2",
            status: UNDER_MAINTENANCE,
            dateAcquired: "2022-11-05",
            schedules: [
                {scheduleId: "SCH-665", 'type: MAINTENANCE, dueDate: "2026-08-20",
                 description: "Firmware update and disk cleanup."}
            ],
            workOrders: [
                {orderId: "WO-610", status: IN_PROGRESS,
                 description: "Boot loop after power outage",
                 tasks: [
                     {taskId: "T1", description: "Reflash firmware."},
                     {taskId: "T2", description: "Replace faulty power supply."}
                 ]}
            ]
        },
        {
            assetTag: "IUM-LIB-PROJ-007",
            name: "Epson EB-X49 Projector",
            description: "Portable projector for lecture halls.",
            institution: "International University of Management",
            site: "Dorado Park Campus - Lecture Hall B",
            status: AVAILABLE,
            dateAcquired: "2024-06-18",
            schedules: [
                {scheduleId: "SCH-540", 'type: SERVICING, dueDate: "2026-12-01",
                 description: "Lamp replacement and filter cleaning."}
            ]
        }
    ];
    foreach var asset in seedAssets {
        assets[asset.assetTag] = asset;
    }
}


