import { Routes } from '@angular/router';
import { Main } from './pages/main/main';
import { Member } from './pages/member/member';
import { List } from './pages/member/list/list';
import { Profile } from './pages/member/profile/profile';
import { Pagenotfound } from './pages/pagenotfound/pagenotfound';
import { Test } from './pages/member/test/test';

export const routes: Routes = [
    { path: '', component: Main },
    {
        path: 'member', 
        component: Member,
        children: [
            { path: 'list', component: List },
            { path: 'profile', component: Profile },
            { path: 'test', component: Test },
            { path: 'test/:id', component: Test },
        ]
    },
    //Wild Card Route for 404 request
    { path: '**', component: Pagenotfound },
];