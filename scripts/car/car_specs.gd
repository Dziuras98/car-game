extends Resource
class_name CarSpecs

@export_group("Identity")
@export var display_name: String = "Car"

@export_group("Driving")
@export var acceleration: float = 22.0
@export var brake_deceleration: float = 34.0
@export var reverse_acceleration: float = 12.0
@export var coast_deceleration: float = 5.0
@export var handbrake_deceleration: float = 18.0
@export var max_forward_speed: float = 30.0
@export var max_reverse_speed: float = 10.0
@export var steering_speed: float = 2.7
@export var wheel_base: float = 2.65
@export var max_steering_angle_degrees: float = 32.0

@export_group("Engine")
@export var idle_rpm: float = 900.0
@export var peak_torque_rpm: float = 4200.0
@export var redline_rpm: float = 6500.0
@export var rev_limiter_rpm: float = 6800.0
@export var low_rpm_torque_multiplier: float = 0.42
@export var mid_rpm_torque_multiplier: float = 0.82
@export var redline_torque_multiplier: float = 0.72
@export var engine_force: float = 30.0
@export var engine_brake_force: float = 3.0
@export var rpm_response: float = 8.0

@export_group("Transmission")
@export var manual_transmission_enabled: bool = false
@export var automatic_transmission_enabled: bool = false
@export var gear_ratios: Array[float] = [3.20, 2.10, 1.50, 1.15, 0.92, 0.75]
@export var reverse_gear_ratio: float = 3.00
@export var final_drive_ratio: float = 3.70
@export var peak_engine_torque: float = 420.0
@export var wheel_radius: float = 0.34
@export var drivetrain_efficiency: float = 0.85
@export var shift_delay: float = 0.28

@export_group("Automatic Transmission")
@export var automatic_upshift_rpm: float = 6200.0
@export var automatic_downshift_rpm: float = 2100.0
@export var automatic_kickdown_throttle: float = 0.82
@export var automatic_kickdown_rpm: float = 5200.0
@export var automatic_shift_delay: float = 0.22
@export var torque_converter_stall_rpm: float = 2600.0
@export var torque_converter_coupling_rpm: float = 4200.0
@export var torque_converter_stall_torque_multiplier: float = 1.65

@export_group("Resistance")
@export var vehicle_mass: float = 1200.0
@export var drag_coefficient: float = 0.30
@export var frontal_area: float = 2.05
@export var air_density: float = 1.225
@export var rolling_resistance_coefficient: float = 0.015

@export_group("Tires")
@export var lateral_grip: float = 10.0
@export var handbrake_lateral_grip_multiplier: float = 0.28
@export var steering_slip_gain: float = 0.85
@export var slip_speed_threshold: float = 2.2
@export var slip_steering_lock_threshold: float = 0.55
@export var slip_steering_same_direction_multiplier: float = 0.12
@export var skid_mark_min_slip: float = 0.45
@export var skid_mark_interval: float = 0.055
@export var skid_mark_lifetime: float = 10.0
@export var skid_mark_width: float = 0.22
@export var skid_mark_length: float = 0.9

@export_group("Grounding")
@export var gravity: float = 30.0
@export var floor_stick_force: float = 0.5
