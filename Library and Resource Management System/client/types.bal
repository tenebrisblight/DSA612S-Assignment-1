
// Status of any tracked asset/resource.
public enum AssetStatus {
    AVAILABLE,
    LOANED_OUT,
    OCCUPIED,
    UNDER_MAINTENANCE,
    DISPOSED
}

// Types of schedules attached to an asset.
public enum ScheduleType {
    MAINTENANCE,
    SERVICING,
    BOOKING
}

// Lifecycle of a work order.
public enum WorkOrderStatus {
    OPEN,
    IN_PROGRESS,
    CLOSED
}

// A replaceable part of a complex asset (e.g. a printer stepper motor).
public type Component record {|
    string compId;
    string name;
    string description;
|};

// A servicing/maintenance/booking entry attached to an asset.
public type Schedule record {|
    string scheduleId;
    ScheduleType 'type;
    string dueDate;
    string description;
|};

//schedule payload used for updates.
public type ScheduleUpdate record {|
    ScheduleType 'type?;
    string dueDate?;
    string description?;
|};

// A sub-task belonging to a work order 
public type Task record {|
    string taskId;
    string description;
|};

// A work order record
public type WorkOrder record {|
    string orderId;
    WorkOrderStatus status;
    string description;
    Task[] tasks = [];
|};

// Work order update record
public type WorkOrderUpdate record {|
    WorkOrderStatus status?;
    string description?;
|};


public type Asset record {|
    readonly string assetTag;
    string name;
    string description;
    string institution;
    string site;
    AssetStatus status;
    string dateAcquired;
    Component[] components = [];
    Schedule[] schedules = [];
    WorkOrder[] workOrders = [];
|};

// Assets update log/record
public type AssetUpdate record {|
    string name?;
    string description?;
    string institution?;
    string site?;
    AssetStatus status?;
    string dateAcquired?;
|};

// record of institions
public type Institution record {|
    readonly string name;
    string location;
|};

//booking record
public type BookingRequest record {|
    string date;
    string description?;
|};

// view of assets past due date
public type OverdueItem record {|
    string assetTag;
    string assetName;
    string institution;
    string scheduleId;
    ScheduleType 'type;
    string dueDate;
    string description;
|};
