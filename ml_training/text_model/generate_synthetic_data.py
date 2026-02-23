"""
Generate synthetic text data for civic issue classification training
"""
import pandas as pd
import random

# Templates for different issue types
road_issues = [
    "Large pothole on {street}",
    "Deep crater in the middle of {street}",
    "Road surface cracked near {landmark}",
    "Uneven pavement on {street}",
    "Damaged asphalt on {street}",
    "Multiple potholes along {street}",
    "Road caving in near {landmark}",
    "Broken road surface at {street}",
    "Severe road damage on {street}",
    "Dangerous pothole on {street} causing accidents",
]

waste_issues = [
    "Overflowing garbage bin at {landmark}",
    "Trash piling up on {street}",
    "Garbage dump on sidewalk near {landmark}",
    "Foul smell from waste at {street}",
    "Litter everywhere in {landmark}",
    "Uncollected garbage for 3 days at {street}",
    "Waste overflow near {landmark}",
    "Garbage bins not emptied at {street}",
    "Illegal dumping at {landmark}",
    "Sanitation issue at {street}",
]

light_issues = [
    "Street light not working on {street}",
    "Broken lamp post at {landmark}",
    "No lights in the alley near {street}",
    "Streetlight flickering on {street}",
    "Dark street due to lighting failure at {street}",
    "Exposed electrical wire near {landmark}",
    "Multiple streetlights out on {street}",
    "Lamp post damaged at {landmark}",
    "Streetlight pole fallen on {street}",
    "Electrical hazard at {landmark}",
]

# Puducherry-specific locations
streets = ["Mission Street", "Beach Road", "Mahatma Gandhi Road", "Nehru Street", "Bharathi Street", 
           "Dumas Street", "Romain Rolland Street", "Vysial Street", "Kamaraj Salai", "ECR Road"]
landmarks = ["Rock Beach", "Promenade Beach", "Botanical Garden", "Bharathi Park", "Auroville", 
             "Paradise Beach", "French War Memorial", "Pondicherry Museum", "Sri Aurobindo Ashram", "Serenity Beach"]

def generate_dataset(num_samples=300):
    data = []
    
    for _ in range(num_samples):
        # Randomly choose issue type
        issue_type = random.choice(['road', 'waste', 'light'])
        
        if issue_type == 'road':
            template = random.choice(road_issues)
            location = random.choice(streets + landmarks)
            text = template.format(street=location, landmark=location)
            department = 0  # Road Maintenance
            severity = random.choices([0, 1, 2, 3], weights=[10, 30, 40, 20])[0]  # Weighted severity
            
        elif issue_type == 'waste':
            template = random.choice(waste_issues)
            location = random.choice(streets + landmarks)
            text = template.format(street=location, landmark=location)
            department = 1  # Sanitation
            severity = random.choices([0, 1, 2, 3], weights=[15, 35, 35, 15])[0]
            
        else:  # light
            template = random.choice(light_issues)
            location = random.choice(streets + landmarks)
            text = template.format(street=location, landmark=location)
            department = 2  # Electrical
            severity = random.choices([0, 1, 2, 3], weights=[20, 40, 30, 10])[0]
        
        data.append({
            'text': text,
            'severity': severity,
            'department': department
        })
    
    return pd.DataFrame(data)

if __name__ == "__main__":
    df = generate_dataset(300)
    output_path = "data.csv"
    df.to_csv(output_path, index=False)
    print(f"Generated {len(df)} samples")
    print(f"Saved to {output_path}")
    print("\nSample data:")
    print(df.head(10))
    print("\nDistribution:")
    print(f"Road issues: {len(df[df['department']==0])}")
    print(f"Waste issues: {len(df[df['department']==1])}")
    print(f"Light issues: {len(df[df['department']==2])}")
