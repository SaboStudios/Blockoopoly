pub mod systems {
    pub mod world;
}
pub mod interfaces {
    pub mod IWorld;
}

pub mod model {
    pub mod game_model;
    pub mod player_model;
    pub mod property_model;
}

pub mod tests {
    mod test_world;
    mod test_player_model;
    mod test_property_enhanced;
}

pub mod utils {
    pub mod property_templates;
}
