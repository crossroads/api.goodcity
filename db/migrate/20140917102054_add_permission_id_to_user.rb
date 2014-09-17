class AddPermissionIdToUser < ActiveRecord::Migration
  def change
    add_reference :users, :permission, index: true
    remove_column :users, :district_id
    # Update the permission id details in User table as
    # per the new migration changes.
    queryToUpdateUserPermission = "UPDATE Users
      set permission_id=tmpPermUser.permId
      from (select U.id as userId, P.permission_id as permId
        from users U
        join permissions_users P  on
        U.id = P.user_id
        order by P.permission_id desc) as tmpPermUser
      where tmpPermUser.userId = Users.id"
    droptable = "drop table permissions_users;"

    User.connection.execute queryToUpdateUserPermission
    # On successful update delete the permissions_users table
    User.connection.execute droptable
  end
end
