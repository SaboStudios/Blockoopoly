// Property templates for standard Monopoly board
// This module provides pre-configured property data for easy game initialization

use starknet::ContractAddress;

#[derive(Copy, Drop, Serde)]
pub struct PropertyTemplate {
    pub id: u8,
    pub name: felt252,
    pub cost: u256,
    pub rent_site_only: u256,
    pub rent_one_house: u256,
    pub rent_two_houses: u256,
    pub rent_three_houses: u256,
    pub rent_four_houses: u256,
    pub cost_of_house: u256,
    pub rent_hotel: u256,
    pub group_id: u8,
}

pub trait PropertyTemplatesImpl {
    fn get_standard_properties() -> Array<(u8, felt252, u256, u256, u256, u256, u256, u256, u256, u256, u8)>;
    fn get_brown_properties() -> Array<(u8, felt252, u256, u256, u256, u256, u256, u256, u256, u256, u8)>;
    fn get_light_blue_properties() -> Array<(u8, felt252, u256, u256, u256, u256, u256, u256, u256, u256, u8)>;
    fn get_pink_properties() -> Array<(u8, felt252, u256, u256, u256, u256, u256, u256, u256, u256, u8)>;
    fn get_orange_properties() -> Array<(u8, felt252, u256, u256, u256, u256, u256, u256, u256, u256, u8)>;
    fn get_red_properties() -> Array<(u8, felt252, u256, u256, u256, u256, u256, u256, u256, u256, u8)>;
    fn get_yellow_properties() -> Array<(u8, felt252, u256, u256, u256, u256, u256, u256, u256, u256, u8)>;
    fn get_green_properties() -> Array<(u8, felt252, u256, u256, u256, u256, u256, u256, u256, u256, u8)>;
    fn get_blue_properties() -> Array<(u8, felt252, u256, u256, u256, u256, u256, u256, u256, u256, u8)>;
    fn get_railroads() -> Array<(u8, felt252, u256, u256, u256, u256, u256, u256, u256, u256, u8)>;
    fn get_utilities() -> Array<(u8, felt252, u256, u256, u256, u256, u256, u256, u256, u256, u8)>;
}

impl PropertyTemplates of PropertyTemplatesImpl {
    fn get_standard_properties() -> Array<(u8, felt252, u256, u256, u256, u256, u256, u256, u256, u256, u8)> {
        let mut properties = ArrayTrait::new();
        
        // Brown Properties (Group 1)
        properties.append((1, 'Mediterranean_Ave', 60, 2, 10, 30, 90, 160, 50, 250, 1));
        properties.append((3, 'Baltic_Ave', 60, 4, 20, 60, 180, 320, 50, 450, 1));
        
        // Light Blue Properties (Group 2)
        properties.append((6, 'Oriental_Ave', 100, 6, 30, 90, 270, 400, 50, 550, 2));
        properties.append((8, 'Vermont_Ave', 100, 6, 30, 90, 270, 400, 50, 550, 2));
        properties.append((9, 'Connecticut_Ave', 120, 8, 40, 100, 300, 450, 50, 600, 2));
        
        // Pink Properties (Group 3)
        properties.append((11, 'St_Charles_Place', 140, 10, 50, 150, 450, 625, 100, 750, 3));
        properties.append((13, 'States_Ave', 140, 10, 50, 150, 450, 625, 100, 750, 3));
        properties.append((14, 'Virginia_Ave', 160, 12, 60, 180, 500, 700, 100, 900, 3));
        
        // Orange Properties (Group 4)
        properties.append((16, 'St_James_Place', 180, 14, 70, 200, 550, 750, 100, 950, 4));
        properties.append((18, 'Tennessee_Ave', 180, 14, 70, 200, 550, 750, 100, 950, 4));
        properties.append((19, 'New_York_Ave', 200, 16, 80, 220, 600, 800, 100, 1000, 4));
        
        // Red Properties (Group 5)
        properties.append((21, 'Kentucky_Ave', 220, 18, 90, 250, 700, 875, 150, 1050, 5));
        properties.append((23, 'Indiana_Ave', 220, 18, 90, 250, 700, 875, 150, 1050, 5));
        properties.append((24, 'Illinois_Ave', 240, 20, 100, 300, 750, 925, 150, 1100, 5));
        
        // Yellow Properties (Group 6)
        properties.append((26, 'Atlantic_Ave', 260, 22, 110, 330, 800, 975, 150, 1150, 6));
        properties.append((27, 'Ventnor_Ave', 260, 22, 110, 330, 800, 975, 150, 1150, 6));
        properties.append((29, 'Marvin_Gardens', 280, 24, 120, 360, 850, 1025, 150, 1200, 6));
        
        // Green Properties (Group 7)
        properties.append((31, 'Pacific_Ave', 300, 26, 130, 390, 900, 1100, 200, 1275, 7));
        properties.append((32, 'North_Carolina_Ave', 300, 26, 130, 390, 900, 1100, 200, 1275, 7));
        properties.append((34, 'Pennsylvania_Ave', 320, 28, 150, 450, 1000, 1200, 200, 1400, 7));
        
        // Blue Properties (Group 8)
        properties.append((37, 'Park_Place', 350, 35, 175, 500, 1100, 1300, 200, 1500, 8));
        properties.append((39, 'Boardwalk', 400, 50, 200, 600, 1400, 1700, 200, 2000, 8));
        
        // Railroads (Group 9)
        properties.append((5, 'Reading_Railroad', 200, 25, 50, 100, 200, 0, 0, 0, 9));
        properties.append((15, 'Pennsylvania_Railroad', 200, 25, 50, 100, 200, 0, 0, 0, 9));
        properties.append((25, 'BO_Railroad', 200, 25, 50, 100, 200, 0, 0, 0, 9));
        properties.append((35, 'Short_Line', 200, 25, 50, 100, 200, 0, 0, 0, 9));
        
        // Utilities (Group 10)
        properties.append((12, 'Electric_Company', 150, 4, 10, 0, 0, 0, 0, 0, 10));
        properties.append((28, 'Water_Works', 150, 4, 10, 0, 0, 0, 0, 0, 10));
        
        properties
    }

    fn get_brown_properties() -> Array<(u8, felt252, u256, u256, u256, u256, u256, u256, u256, u256, u8)> {
        let mut properties = ArrayTrait::new();
        properties.append((1, 'Mediterranean_Ave', 60, 2, 10, 30, 90, 160, 50, 250, 1));
        properties.append((3, 'Baltic_Ave', 60, 4, 20, 60, 180, 320, 50, 450, 1));
        properties
    }

    fn get_light_blue_properties() -> Array<(u8, felt252, u256, u256, u256, u256, u256, u256, u256, u256, u8)> {
        let mut properties = ArrayTrait::new();
        properties.append((6, 'Oriental_Ave', 100, 6, 30, 90, 270, 400, 50, 550, 2));
        properties.append((8, 'Vermont_Ave', 100, 6, 30, 90, 270, 400, 50, 550, 2));
        properties.append((9, 'Connecticut_Ave', 120, 8, 40, 100, 300, 450, 50, 600, 2));
        properties
    }

    fn get_pink_properties() -> Array<(u8, felt252, u256, u256, u256, u256, u256, u256, u256, u256, u8)> {
        let mut properties = ArrayTrait::new();
        properties.append((11, 'St_Charles_Place', 140, 10, 50, 150, 450, 625, 100, 750, 3));
        properties.append((13, 'States_Ave', 140, 10, 50, 150, 450, 625, 100, 750, 3));
        properties.append((14, 'Virginia_Ave', 160, 12, 60, 180, 500, 700, 100, 900, 3));
        properties
    }

    fn get_orange_properties() -> Array<(u8, felt252, u256, u256, u256, u256, u256, u256, u256, u256, u8)> {
        let mut properties = ArrayTrait::new();
        properties.append((16, 'St_James_Place', 180, 14, 70, 200, 550, 750, 100, 950, 4));
        properties.append((18, 'Tennessee_Ave', 180, 14, 70, 200, 550, 750, 100, 950, 4));
        properties.append((19, 'New_York_Ave', 200, 16, 80, 220, 600, 800, 100, 1000, 4));
        properties
    }

    fn get_red_properties() -> Array<(u8, felt252, u256, u256, u256, u256, u256, u256, u256, u256, u8)> {
        let mut properties = ArrayTrait::new();
        properties.append((21, 'Kentucky_Ave', 220, 18, 90, 250, 700, 875, 150, 1050, 5));
        properties.append((23, 'Indiana_Ave', 220, 18, 90, 250, 700, 875, 150, 1050, 5));
        properties.append((24, 'Illinois_Ave', 240, 20, 100, 300, 750, 925, 150, 1100, 5));
        properties
    }

    fn get_yellow_properties() -> Array<(u8, felt252, u256, u256, u256, u256, u256, u256, u256, u256, u8)> {
        let mut properties = ArrayTrait::new();
        properties.append((26, 'Atlantic_Ave', 260, 22, 110, 330, 800, 975, 150, 1150, 6));
        properties.append((27, 'Ventnor_Ave', 260, 22, 110, 330, 800, 975, 150, 1150, 6));
        properties.append((29, 'Marvin_Gardens', 280, 24, 120, 360, 850, 1025, 150, 1200, 6));
        properties
    }

    fn get_green_properties() -> Array<(u8, felt252, u256, u256, u256, u256, u256, u256, u256, u256, u8)> {
        let mut properties = ArrayTrait::new();
        properties.append((31, 'Pacific_Ave', 300, 26, 130, 390, 900, 1100, 200, 1275, 7));
        properties.append((32, 'North_Carolina_Ave', 300, 26, 130, 390, 900, 1100, 200, 1275, 7));
        properties.append((34, 'Pennsylvania_Ave', 320, 28, 150, 450, 1000, 1200, 200, 1400, 7));
        properties
    }

    fn get_blue_properties() -> Array<(u8, felt252, u256, u256, u256, u256, u256, u256, u256, u256, u8)> {
        let mut properties = ArrayTrait::new();
        properties.append((37, 'Park_Place', 350, 35, 175, 500, 1100, 1300, 200, 1500, 8));
        properties.append((39, 'Boardwalk', 400, 50, 200, 600, 1400, 1700, 200, 2000, 8));
        properties
    }

    fn get_railroads() -> Array<(u8, felt252, u256, u256, u256, u256, u256, u256, u256, u256, u8)> {
        let mut properties = ArrayTrait::new();
        properties.append((5, 'Reading_Railroad', 200, 25, 50, 100, 200, 0, 0, 0, 9));
        properties.append((15, 'Pennsylvania_Railroad', 200, 25, 50, 100, 200, 0, 0, 0, 9));
        properties.append((25, 'BO_Railroad', 200, 25, 50, 100, 200, 0, 0, 0, 9));
        properties.append((35, 'Short_Line', 200, 25, 50, 100, 200, 0, 0, 0, 9));
        properties
    }

    fn get_utilities() -> Array<(u8, felt252, u256, u256, u256, u256, u256, u256, u256, u256, u8)> {
        let mut properties = ArrayTrait::new();
        properties.append((12, 'Electric_Company', 150, 4, 10, 0, 0, 0, 0, 0, 10));
        properties.append((28, 'Water_Works', 150, 4, 10, 0, 0, 0, 0, 0, 10));
        properties
    }
} 