
const loadButton = document.getElementById("load-users");
const filterInput = document.getElementById("filter-input");
const status = document.getElementById("status");
const usersList = document.getElementById("users-list");

let users = [];
let hasLoaded = false;

async function loadUsers() {
  loadButton.disabled = true;
  status.textContent = "Loading users...";
  usersList.replaceChildren();

  try {
    const response = await fetch(
      "https://jsonplaceholder.typicode.com/users"
    );

    if (!response.ok) {
      throw new Error("Failed to fetch users.");
    }

    users = await response.json();
    hasLoaded = true;

    // Start with an empty filter after loading.
    filterInput.value = "";

    renderUsers(users);
    status.textContent = `Loaded ${users.length} users.`;
  } catch (error) {
    users = [];
    hasLoaded = false;
    usersList.replaceChildren();
    status.textContent = "Error loading users. Please try again.";
    console.error(error);
  } finally {
    loadButton.disabled = false;
  }
}

function renderUsers(list) {
  usersList.replaceChildren();

  if (list.length === 0) {
    status.textContent = "No users match your filter.";
    return;
  }

  list.forEach((user) => {
    const li = document.createElement("li");

    const name = document.createElement("h3");
    name.textContent = user.name;

    const email = document.createElement("p");
    email.textContent = `Email: ${user.email}`;

    const city = document.createElement("p");
    city.textContent = `City: ${user.address.city}`;

    const company = document.createElement("p");
    company.textContent = `Company: ${user.company.name}`;

    li.append(name, email, city, company);
    usersList.appendChild(li);
  });

  status.textContent = `Showing ${list.length} users.`;
}

loadButton.addEventListener("click", loadUsers);

filterInput.addEventListener("input", () => {
  // Don't filter before users have been loaded successfully.
  if (!hasLoaded) {
    return;
  }

  const searchText = filterInput.value.toLowerCase().trim();

  const filteredUsers = users.filter((user) =>
    user.name.toLowerCase().includes(searchText)
  );

  renderUsers(filteredUsers);
});
