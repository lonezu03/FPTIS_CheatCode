CREATE TABLE mobile_menu_settings (
    id integer PRIMARY KEY CHECK (id = 1),
    version bigint NOT NULL DEFAULT 0,
    modules_json text NOT NULL,
    updated_at timestamp NOT NULL,
    updated_by varchar(255)
);
INSERT INTO mobile_menu_settings (id, version, modules_json, updated_at)
VALUES (1, 0, '[{"key":"dashboard","visible":true},{"key":"lunch","visible":true},{"key":"fitness","visible":true},{"key":"workoutPlans","visible":true},{"key":"exercises","visible":true},{"key":"nutrition","visible":true},{"key":"foods","visible":true},{"key":"health","visible":true},{"key":"planner","visible":true},{"key":"quotes","visible":true},{"key":"finance","visible":true},{"key":"journal","visible":true},{"key":"assistant","visible":true}]', CURRENT_TIMESTAMP);
