﻿using System;
using System.Linq;
using System.Collections.Generic;
using System.Text;
using NETCoreSyncMobileSample.Models;

namespace NETCoreSyncMobileSample.ViewModels
{
    public class EmployeeListViewModel : CustomBaseViewModel
    {
        public EmployeeListViewModel()
        {
            Title = HomeMenuItem.GetMenus().Where(w => w.Id == MenuItemType.EmployeeList).First().Title;
        }
    }
}
