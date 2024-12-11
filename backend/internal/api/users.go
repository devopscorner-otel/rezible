package api

import (
	"context"
	rez "github.com/twohundreds/rezible"
	oapi "github.com/twohundreds/rezible/openapi"
)

type usersHandler struct {
	users rez.UserService
}

func newUsersHandler(users rez.UserService) *usersHandler {
	return &usersHandler{users}
}

func (h *usersHandler) ListUsers(ctx context.Context, request *oapi.ListUsersRequest) (*oapi.ListUsersResponse, error) {
	var resp oapi.ListUsersResponse

	users, usersErr := h.users.ListUsers(ctx, rez.ListUsersParams{
		ListParams: request.ListParams(),
	})
	if usersErr != nil {
		return nil, detailError("failed to list users", usersErr)
	}

	resp.Body.Data = make([]oapi.User, len(users))
	for i, u := range users {
		resp.Body.Data[i] = oapi.UserFromEnt(u)
	}

	return &resp, nil
}

func (h *usersHandler) GetUser(ctx context.Context, input *oapi.GetUserRequest) (*oapi.GetUserResponse, error) {
	var resp oapi.GetUserResponse

	user, getErr := h.users.GetById(ctx, input.Id)
	if getErr != nil {
		return nil, detailError("Failed to get user", getErr)
	}
	resp.Body.Data = oapi.UserFromEnt(user)

	return &resp, nil
}
