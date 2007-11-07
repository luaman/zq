
void TeamFortress_CTF_FlagInfo () {
    entity te;
    te = Finditem (1);
    if ( (te.goal_state == 1) ) {
        if ( (self == te.owner) ) {
            sprint (self,PRINT_HIGH,"You have the enemy flag.\n");
        } else {
            sprint (self,PRINT_HIGH,te.owner.netname);
            sprint (self,PRINT_HIGH," has");
            if ( (self.pteam == pteam1) ) {
                sprint (self,PRINT_HIGH," your flag.\n");
            } else {
                sprint (self,PRINT_HIGH," the enemy flag.\n");
            }
        }
    } else {
        if ( (te.origin != te.oldorigin) ) {
            if ( (self.pteam == pteam1) ) {
                sprint (self,PRINT_HIGH,"Your flag is lying about.\n");
            } else {
                sprint (self,PRINT_HIGH,"The enemy flag is lying about.\n");
            }
        } else {
            if ( (self.pteam == pteam1) ) {
                sprint (self,PRINT_HIGH,"Your flag is in your base.\n");
            } else {
                sprint (self,PRINT_HIGH,"The enemy flag is in their base.\n");
            }
        }
    }
    te = Finditem (2);
    if ( (te.goal_state == 1) ) {
        if ( (self == te.owner) ) {
            sprint (self,PRINT_HIGH,"You have the enemy flag.\n");
        } else {
            sprint (self,PRINT_HIGH,te.owner.netname);
            sprint (self,PRINT_HIGH," has");
            if ( (self.pteam == pteam2) ) {
                sprint (self,PRINT_HIGH," your flag.\n");
            } else {
                sprint (self,PRINT_HIGH," the enemy flag.\n");
            }
        }
    } else {
        if ( (te.origin != te.oldorigin) ) {
            if ( (self.pteam == pteam2) ) {
                sprint (self,PRINT_HIGH,"Your flag is lying about.\n");
            } else {
                sprint (self,PRINT_HIGH,"The enemy flag is lying about.\n");
            }
        } else {
            if ( (self.pteam == pteam2) ) {
                sprint (self,PRINT_HIGH,"Your flag is in your base.\n");
            } else {
                sprint (self,PRINT_HIGH,"The enemy flag is in their base.\n");
            }
        }
    }
}
