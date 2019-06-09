﻿using System;

using Xamarin.Forms;
using Xamarin.Forms.Xaml;
using NETCoreSyncMobileSample.ViewModels;

namespace NETCoreSyncMobileSample.Views
{
    [XamlCompilation(XamlCompilationOptions.Compile)]
    public partial class AboutPage : BaseContentPage<AboutViewModel>
    {
        public AboutPage()
        {
            InitializeComponent();
            BindingContext = ViewModel;
        }
    }
}