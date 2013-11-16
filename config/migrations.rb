migration 1, :create_games_table do
  up do
    create_table :games do
      column :id, Integer, :serial => true
      column :home_team, String
      column :away_team, String
      column :bbref_key, String
      column :slug, String
      column :date, DateTime
    end
  end

  down do
    drop_table :games
  end
end

migration 2, :create_events_table do
  up do
    create_table :events do
      column :id, Integer, :serial => true
      column :game_id, Integer
      column :player, String
      column :type, String
      column :time, Integer
      column :name, String
      column :team, Integer
    end
  end

  down do
    drop_table :events
  end
end

migration 3, :add_game_quality do
  up do
    modify_table :games do
      add_column :quality, Integer
    end
  end

  down do
    modify_table :games do
      drop_column :quality
    end
  end
end

migration 4, :enable_multiple_providers do
  up do
    modify_table :games do
      add_column :provider, String, default: 'bbref'
    end
  end

  down do
    modify_table :games do
      drop_column :provider
    end
  end  
end
